import { createHash, randomBytes } from "node:crypto";
import { CreateUserDto } from "@auth/users/application/dto/create-user.dto";
import { LoginDto } from "@auth/users/application/dto/login.dto";
import { RequestPasswordResetDto } from "@auth/users/application/dto/request-password-reset.dto";
import { ResetPasswordTokenDto } from "@auth/users/application/dto/reset-password-token.dto";
import { UserDto } from "@auth/users/application/dto/user.dto";
import { PasswordResetToken } from "@auth/users/domain/models/password-reset-token.entity";
import { User } from "@auth/users/domain/models/user.entity";
import {
  PASSWORD_RESET_TOKEN_REPOSITORY,
  type PasswordResetTokenRepository,
} from "@auth/users/domain/repositories/password-reset-token-repository.interface";
import {
  USER_REPOSITORY,
  type UserRepository,
} from "@auth/users/domain/repositories/user-repository.interface";
import { EmailService } from "@auth/users/infra/email/email.service";
import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import {
  UserAuthExchangeName,
  UserAuthRoutingKey,
} from "@shared/contracts/events/user-auth-events.enum";
import { ROLE_PERMISSIONS } from "@shared/domain/enums/permission.enum";
import { SharedMessagingService } from "@shared/infra/messaging/shared-messaging.service";
import * as bcrypt from "bcryptjs";

const PASSWORD_RESET_TTL_MINUTES = Number(
  process.env.PASSWORD_RESET_TTL_MINUTES ?? 30,
);
const PASSWORD_RESET_GENERIC_MESSAGE =
  "Se o e-mail estiver cadastrado, enviaremos as instruções de recuperação";

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    @Inject(PASSWORD_RESET_TOKEN_REPOSITORY)
    private readonly passwordResetTokenRepository: PasswordResetTokenRepository,
    private readonly emailService: EmailService,
    private readonly jwtService: JwtService,
    private readonly messaging: SharedMessagingService,
  ) {}

  async register(
    dto: CreateUserDto,
  ): Promise<{ accessToken: string; user: UserDto }> {
    const [existingEmail, existingCpf] = await Promise.all([
      this.userRepository.findByEmail(dto.email),
      this.userRepository.findByCpf(dto.cpf),
    ]);

    if (existingEmail) throw new ConflictException("Email já cadastrado");
    if (existingCpf) throw new ConflictException("CPF já cadastrado");

    if (dto.birthDate && this.ageInYears(dto.birthDate) < 18) {
      throw new BadRequestException(
        "É necessário ter 18 anos ou mais para se cadastrar",
      );
    }

    const role = dto.role ?? "CLIENTE";
    const permissions = ROLE_PERMISSIONS[role] ?? [];
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    const user = User.restore({
      name: dto.name,
      email: dto.email.toLowerCase(),
      password: hashedPassword,
      phone: dto.phone,
      cpf: dto.cpf,
      birthDate: dto.birthDate ?? null,
      role,
      permissions,
    })!;

    await this.userRepository.create(user);

    const created = await this.userRepository.findByEmail(
      dto.email.toLowerCase(),
    );
    if (!created) throw new NotFoundException("Usuário criado não encontrado");

    await this.safePublish(
      UserAuthExchangeName.USER_CREATED,
      UserAuthRoutingKey.USER_CREATED,
      {
        userId: created.id,
        name: created.name,
        email: created.email,
      },
    );

    const accessToken = this.generateToken(created);
    return { accessToken, user: UserDto.fromUser(created)! };
  }

  async login(dto: LoginDto): Promise<{ accessToken: string; user: UserDto }> {
    const user = await this.userRepository.findByEmail(dto.email.toLowerCase());

    if (!user) throw new UnauthorizedException("Credenciais inválidas");

    const valid = await bcrypt.compare(dto.password, user.password);
    if (!valid) throw new UnauthorizedException("Credenciais inválidas");

    const accessToken = this.generateToken(user);
    return { accessToken, user: UserDto.fromUser(user)! };
  }

  /**
   * Gera um token de recuperação e o envia por e-mail. Por segurança a resposta
   * é sempre genérica (não revela se o e-mail existe) e o token nunca é
   * retornado pela API — apenas seu hash é persistido.
   */
  async requestPasswordReset(
    dto: RequestPasswordResetDto,
  ): Promise<{ message: string }> {
    const user = await this.userRepository.findByEmail(dto.email.toLowerCase());

    if (!user?.id) return { message: PASSWORD_RESET_GENERIC_MESSAGE };

    await this.passwordResetTokenRepository.deleteActiveByUserId(user.id);

    const rawToken = randomBytes(32).toString("hex");
    const expiresAt = new Date(
      Date.now() + PASSWORD_RESET_TTL_MINUTES * 60 * 1000,
    );

    await this.passwordResetTokenRepository.create(
      PasswordResetToken.restore({
        userId: user.id,
        token: this.hashToken(rawToken),
        expiresAt,
      }),
    );

    const resetUrl = `${process.env.APP_RESET_URL ?? "http://localhost/reset-password"}?token=${rawToken}`;
    await this.emailService.send({
      to: user.email,
      subject: "Recuperação de senha · MyPet",
      text: this.buildResetEmailText(user.name, rawToken, resetUrl),
      html: this.buildResetEmailHtml(user.name, rawToken, resetUrl),
    });

    return { message: PASSWORD_RESET_GENERIC_MESSAGE };
  }

  async resetPassword(
    dto: ResetPasswordTokenDto,
  ): Promise<{ message: string }> {
    const resetToken = await this.passwordResetTokenRepository.findByToken(
      this.hashToken(dto.token),
    );

    if (!resetToken?.id || !resetToken.isValid()) {
      throw new BadRequestException("Token inválido ou expirado");
    }

    const user = await this.userRepository.findById(resetToken.userId);
    if (!user) throw new NotFoundException("Usuário não encontrado");

    user.withPassword(await bcrypt.hash(dto.password, 10));

    await this.userRepository.update(user);
    await this.passwordResetTokenRepository.markUsed(resetToken.id);

    this.logger.log(`Senha redefinida para o usuário ${user.id}`);
    return { message: "Senha redefinida com sucesso" };
  }

  /** Idade completa em anos a partir de uma data de nascimento (ISO). */
  private ageInYears(birthDate: string): number {
    const birth = new Date(birthDate);
    const now = new Date();
    let age = now.getFullYear() - birth.getFullYear();
    const monthDiff = now.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && now.getDate() < birth.getDate())) {
      age--;
    }
    return age;
  }

  private generateToken(user: User): string {
    const permissions = ROLE_PERMISSIONS[user.role] ?? user.permissions;
    return this.jwtService.sign({
      sub: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
      permissions,
    });
  }

  private async safePublish(
    exchange: string,
    routingKey: string,
    payload: unknown,
  ): Promise<void> {
    try {
      await this.messaging.assertExchange(exchange, "direct");
      await this.messaging.publish(exchange, routingKey, payload);
    } catch (err) {
      this.logger.warn(`RabbitMQ publish failed [${routingKey}]: ${err}`);
    }
  }

  private hashToken(token: string): string {
    return createHash("sha256").update(token).digest("hex");
  }

  private buildResetEmailText(
    name: string,
    token: string,
    resetUrl: string,
  ): string {
    return [
      `Olá, ${name}.`,
      "",
      "Recebemos um pedido para redefinir a senha da sua conta MyPet.",
      "Use o código abaixo no aplicativo para criar uma nova senha:",
      "",
      token,
      "",
      `Ou acesse: ${resetUrl}`,
      "",
      `Este código expira em ${PASSWORD_RESET_TTL_MINUTES} minutos. Se você não solicitou a recuperação, ignore este e-mail.`,
      "",
      "Equipe MyPet",
    ].join("\n");
  }

  private buildResetEmailHtml(
    name: string,
    token: string,
    resetUrl: string,
  ): string {
    return `
      <div style="font-family: Arial, sans-serif; color: #2D2D2D; max-width: 480px; margin: 0 auto;">
        <h2 style="color: #7B3FF2;">Recuperação de senha</h2>
        <p>Olá, ${name}.</p>
        <p>Recebemos um pedido para redefinir a senha da sua conta <strong>MyPet</strong>.</p>
        <p>Use o código abaixo no aplicativo para criar uma nova senha:</p>
        <p style="font-size: 16px; font-weight: bold; background: #F4F0FF; padding: 12px 16px; border-radius: 8px; letter-spacing: 1px; word-break: break-all;">${token}</p>
        <p>Ou clique no botão abaixo:</p>
        <p>
          <a href="${resetUrl}" style="display: inline-block; background: #7B3FF2; color: #fff; text-decoration: none; padding: 12px 20px; border-radius: 8px;">Redefinir senha</a>
        </p>
        <p style="color: #888; font-size: 13px;">Este código expira em ${PASSWORD_RESET_TTL_MINUTES} minutos. Se você não solicitou a recuperação, ignore este e-mail.</p>
        <p style="color: #888; font-size: 13px;">Equipe MyPet</p>
      </div>
    `;
  }
}
