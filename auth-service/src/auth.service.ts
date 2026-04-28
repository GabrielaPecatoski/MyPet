import {
  Injectable,
  Logger,
  UnauthorizedException,
  ConflictException,
  InternalServerErrorException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { User, Role } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import * as http from 'http';
import { PrismaService } from './prisma.service';
import { LoginDto, RegisterDto } from './login.dto';

const ESTAB_URL =
  process.env.ESTABLISHMENT_SERVICE_URL ?? 'http://localhost:3003';

function createEstablishment(
  ownerId: string,
  name: string,
  phone: string,
  businessName?: string,
): void {
  const body = JSON.stringify({
    name: businessName || name,
    phone,
    description: '',
    address: '',
    city: '',
    type: 'PET_SHOP',
  });
  const url = new URL(`/establishments/owner/${ownerId}`, ESTAB_URL);
  const req = http.request({
    hostname: url.hostname,
    port: Number(url.port) || 3003,
    path: url.pathname,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(body),
    },
  });
  req.on('error', () => {});
  req.write(body);
  req.end();
}

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (!user || !(await bcrypt.compare(dto.password, user.password))) {
      throw new UnauthorizedException('Email ou senha inválidos');
    }

    return {
      access_token: this.generateToken(user),
      user: this.toPublic(user),
    };
  }

  async register(dto: RegisterDto) {
    const existing = await this.prisma.user.findUnique({
      where: { email: dto.email },
    });

    if (existing) {
      throw new ConflictException('Email já cadastrado');
    }

    const hashed = await bcrypt.hash(dto.password, 10);

    let user: User;
    try {
      user = await this.prisma.user.create({
        data: {
          name: dto.name,
          email: dto.email,
          password: hashed,
          phone: dto.phone,
          cpf: dto.cpf,
          role: dto.role === 'VENDEDOR' ? Role.VENDEDOR : Role.CLIENTE,
        },
      });
    } catch (e: unknown) {
      const err = e as { code?: string; meta?: { target?: string[] }; message?: string };
      this.logger.error('Erro ao criar usuário', err?.message);
      if (err?.code === 'P2002') {
        const field = err?.meta?.target?.includes('cpf') ? 'CPF' : 'Email';
        throw new ConflictException(`${field} já cadastrado`);
      }
      throw new InternalServerErrorException(
        `Erro ao criar conta: ${err?.message ?? 'erro desconhecido'}`,
      );
    }

    if (user.role === Role.VENDEDOR) {
      createEstablishment(user.id, user.name, user.phone, dto.businessName);
    }

    return {
      access_token: this.generateToken(user),
      user: this.toPublic(user),
    };
  }

  extractUserId(authHeader?: string): string | null {
    if (!authHeader?.startsWith('Bearer ')) return null;
    try {
      const payload = this.jwtService.verify<{ sub: string }>(
        authHeader.split(' ')[1],
      );
      return payload.sub ?? null;
    } catch {
      return null;
    }
  }

  async me(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('Usuário não encontrado');
    return this.toPublic(user);
  }

  async refresh(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new UnauthorizedException('Usuário não encontrado');
    return {
      access_token: this.generateToken(user),
      user: this.toPublic(user),
    };
  }

  private generateToken(user: User): string {
    const payload = {
      sub: user.id,
      email: user.email,
      name: user.name,
      role: user.role,
    };
    return this.jwtService.sign(payload);
  }

  private toPublic(user: User) {
    return {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      role: user.role,
    };
  }

  async forgotPassword(email: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    const code = Math.random().toString(36).substring(2, 8).toUpperCase();
    const expiresAt = new Date(Date.now() + 15 * 60 * 1000);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        resetToken: code,
        resetTokenExpires: expiresAt,
      },
    });

    const body = JSON.stringify({
      email: user.email,
      name: user.name,
      code,
    });

    const notifUrl = process.env.NOTIFICATION_SERVICE_URL ?? 'http://localhost:3006';
    const url = new URL('/email/send-reset-password', notifUrl);
    const req = http.request({
      hostname: url.hostname,
      port: Number(url.port) || 3006,
      path: url.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(body),
      },
    });
    req.on('error', () => {});
    req.write(body);
    req.end();

    return {
      message: 'Código de recuperação enviado para o email',
    };
  }

  async verifyResetCode(email: string, code: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    if (!user.resetToken || !user.resetTokenExpires) {
      throw new UnauthorizedException('Código de recuperação não solicitado');
    }

    if (user.resetToken !== code) {
      throw new UnauthorizedException('Código inválido');
    }

    if (new Date() > user.resetTokenExpires) {
      throw new UnauthorizedException('Código expirado');
    }

    return {
      message: 'Código validado com sucesso',
    };
  }

  async resetPassword(email: string, code: string, newPassword: string) {
    const user = await this.prisma.user.findUnique({
      where: { email },
    });

    if (!user) {
      throw new UnauthorizedException('Usuário não encontrado');
    }

    if (!user.resetToken || !user.resetTokenExpires) {
      throw new UnauthorizedException('Código de recuperação não solicitado');
    }

    if (user.resetToken !== code) {
      throw new UnauthorizedException('Código inválido');
    }

    if (new Date() > user.resetTokenExpires) {
      throw new UnauthorizedException('Código expirado');
    }

    const hashed = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: { id: user.id },
      data: {
        password: hashed,
        resetToken: null,
        resetTokenExpires: null,
      },
    });

    return {
      message: 'Senha resetada com sucesso',
    };
  }
}
