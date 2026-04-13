import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { LoginDto, RegisterDto } from './login.dto';
import * as crypto from 'crypto';

interface User {
  id: string;
  name: string;
  email: string;
  password: string;
  phone: string;
  cpf: string;
  role: 'ADMIN' | 'CLIENTE' | 'VENDEDOR';
}

@Injectable()
export class AuthService {
  private readonly users: User[] = [
    // ── Usuários pré-criados para apresentação ──────────────────
    {
      id: 'admin-001',
      name: 'Admin MyPet',
      email: 'admin@mypet.com',
      password: 'admin123',
      phone: '(11) 99999-0001',
      cpf: '000.000.000-00',
      role: 'ADMIN',
    },
    {
      id: 'cliente-001',
      name: 'João Silva',
      email: 'joao@mypet.com',
      password: 'cliente123',
      phone: '(11) 99999-9999',
      cpf: '123.456.789-00',
      role: 'CLIENTE',
    },
    {
      id: 'vendedor-001',
      name: 'Pet Shop Amor & Carinho',
      email: 'petshop@mypet.com',
      password: 'vendedor123',
      phone: '(11) 3456-7890',
      cpf: '99.999.999/0001-99',
      role: 'VENDEDOR',
    },
  ];

  login(dto: LoginDto) {
    const user = this.users.find((u) => u.email === dto.email);
    if (!user || user.password !== dto.password) {
      throw new UnauthorizedException('Email ou senha inválidos');
    }
    return {
      access_token: this.generateToken(user),
      user: this.toPublic(user),
    };
  }

  register(dto: RegisterDto) {
    const existing = this.users.find((u) => u.email === dto.email);
    if (existing) {
      throw new ConflictException('Email já cadastrado');
    }
    const user: User = {
      id: crypto.randomUUID(),
      name: dto.name,
      email: dto.email,
      password: dto.password,
      phone: dto.phone,
      cpf: dto.cpf,
      role: 'CLIENTE',
    };
    this.users.push(user);
    return {
      access_token: this.generateToken(user),
      user: this.toPublic(user),
    };
  }

  private generateToken(user: User): string {
    const payload = { sub: user.id, email: user.email, name: user.name, role: user.role };
    return Buffer.from(JSON.stringify(payload)).toString('base64');
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
}
