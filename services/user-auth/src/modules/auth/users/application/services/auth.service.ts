import { CreateUserDto } from "@auth/users/application/dto/create-user.dto";
import { ForgotPasswordDto } from "@auth/users/application/dto/forgot-password.dto";
import { LoginDto } from "@auth/users/application/dto/login.dto";
import { ResetPasswordDto } from "@auth/users/application/dto/reset-password.dto";
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
import { ROLE_PERMISSIONS } from "@shared/domain/enums/permission.enum";
import { PasswordValidator } from "@common/validators";
import {
  BadRequestException,
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { randomBytes } from "crypto";
import * as bcrypt from "bcryptjs";

@Injectable()
export class AuthService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    @Inject(PASSWORD_RESET_TOKEN_REPOSITORY)
    private readonly passwordResetTokenRepository: PasswordResetTokenRepository,
    private readonly jwtService: JwtService,
  ) {}

  async register(dto: CreateUserDto): Promise<{ accessToken: string; user: UserDto }> {
    const [existingEmail, existingCpf] = await Promise.all([
      this.userRepository.findByEmail(dto.email),
      this.userRepository.findByCpf(dto.cpf),
    ]);

    if (existingEmail) throw new ConflictException("Email já cadastrado");
    if (existingCpf) throw new ConflictException("CPF já cadastrado");

    PasswordValidator.validateOrThrow(dto.password);

    const role = dto.role ?? "CLIENTE";
    const permissions = ROLE_PERMISSIONS[role] ?? [];
    const hashedPassword = await bcrypt.hash(dto.password, 10);

    const user = User.restore({
      name: dto.name,
      email: dto.email.toLowerCase(),
      password: hashedPassword,
      phone: dto.phone,
      cpf: dto.cpf,
      role,
      permissions,
    })!;

    await this.userRepository.create(user);

    const created = await this.userRepository.findByEmail(dto.email.toLowerCase());
    if (!created) throw new NotFoundException("Usuário criado não encontrado");

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

  async forgotPassword(dto: ForgotPasswordDto): Promise<{ message: string }> {
    const user = await this.userRepository.findByEmail(dto.email.toLowerCase());

    if (!user) throw new NotFoundException("Usuário não encontrado");

    await this.passwordResetTokenRepository.deleteByUserId(user.id!);

    const tokenString = randomBytes(32).toString("hex");
    const token = PasswordResetToken.create(user.id!, tokenString, 3600000);

    await this.passwordResetTokenRepository.create(token);

    return { message: "Email de recuperação enviado com sucesso" };
  }

  async resetPassword(dto: ResetPasswordDto): Promise<{ message: string }> {
    const token = await this.passwordResetTokenRepository.findByToken(dto.token);

    if (!token) throw new BadRequestException("Token de recuperação inválido");

    if (token.isExpired()) throw new BadRequestException("Token de recuperação expirado");

    if (token.isAlreadyUsed()) throw new BadRequestException("Token de recuperação já foi utilizado");

    const user = await this.userRepository.findById(token.userId);
    if (!user) throw new NotFoundException("Usuário não encontrado");

    PasswordValidator.validateOrThrow(dto.newPassword);

    const hashedPassword = await bcrypt.hash(dto.newPassword, 10);
    user.withPassword(hashedPassword);

    await this.userRepository.update(user);

    token.withUsedAt(new Date());
    await this.passwordResetTokenRepository.update(token);

    return { message: "Senha alterada com sucesso" };
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
}
