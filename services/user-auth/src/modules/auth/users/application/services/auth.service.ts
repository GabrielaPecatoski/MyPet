import { CreateUserDto } from "@auth/users/application/dto/create-user.dto";
import { LoginDto } from "@auth/users/application/dto/login.dto";
import { UserDto } from "@auth/users/application/dto/user.dto";
import { User } from "@auth/users/domain/models/user.entity";
import {
  USER_REPOSITORY,
  type UserRepository,
} from "@auth/users/domain/repositories/user-repository.interface";
import {
  ConflictException,
  Inject,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import { ROLE_PERMISSIONS } from "@shared/domain/enums/permission.enum";
import * as bcrypt from "bcryptjs";

@Injectable()
export class AuthService {
  constructor(
    @Inject(USER_REPOSITORY)
    private readonly userRepository: UserRepository,
    private readonly jwtService: JwtService,
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

    const created = await this.userRepository.findByEmail(
      dto.email.toLowerCase(),
    );
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
