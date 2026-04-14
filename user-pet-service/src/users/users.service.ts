// @ts-ignore
import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
declare const process: any;
// @ts-ignore
import { v4 as uuidv4 } from 'uuid';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { User, UserRole } from './entities/user.entity';

@Injectable()
export class UsersService {
  private users: User[] = [];

  private validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  private validateCpf(cpf: string): boolean {
    const cleanCpf = cpf.replace(/\D/g, '');
    return cleanCpf.length === 11;
  }

  private validatePhone(phone: string): boolean {
    const cleanPhone = phone.replace(/\D/g, '');
    return cleanPhone.length >= 10;
  }

  async create(createUserDto: CreateUserDto): Promise<Omit<User, 'password'>> {
    if (!this.validateEmail(createUserDto.email)) {
      throw new BadRequestException('Formato de email inválido');
    }

    const existingUser = this.users.find((u) => u.email === createUserDto.email.toLowerCase());
    if (existingUser) {
      throw new ConflictException('Email já registrado no sistema');
    }

    if (!this.validateCpf(createUserDto.cpf)) {
      throw new BadRequestException('CPF deve conter 11 dígitos');
    }

    const existingByCpf = this.users.find((u) => u.cpf === createUserDto.cpf.replace(/\D/g, ''));
    if (existingByCpf) {
      throw new ConflictException('CPF já registrado no sistema');
    }

    if (!this.validatePhone(createUserDto.phone)) {
      throw new BadRequestException('Telefone deve conter no mínimo 10 dígitos');
    }

    if (!createUserDto.password || createUserDto.password.length < 6) {
      throw new BadRequestException('Senha deve ter no mínimo 6 caracteres');
    }

    if (!createUserDto.name || createUserDto.name.trim().length === 0) {
      throw new BadRequestException('Nome é obrigatório');
    }

    const user = new User({
      id: uuidv4(),
      email: createUserDto.email.toLowerCase().trim(),
      name: createUserDto.name.trim(),
      phone: createUserDto.phone.replace(/\D/g, ''),
      birthDate: createUserDto.birthDate,
      cpf: createUserDto.cpf.replace(/\D/g, ''),
      role: UserRole.PET_OWNER,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    this.users.push(user as any);
    return user as any;
  }

  /**
   * Busca usuário por ID
   */
  async findById(id: string): Promise<Omit<User, 'password'>> {
    const user = this.users.find((u) => u.id === id);
    if (!user) {
      throw new NotFoundException(`Usuário com ID "${id}" não encontrado`);
    }
    return user as any;
  }

  /**
   * Busca usuário por email
   */
  async findByEmail(email: string): Promise<Omit<User, 'password'> | undefined> {
    const user = this.users.find((u) => u.email === email.toLowerCase());
    if (user) {
      return user as any;
    }
    return undefined;
  }

  /**
   * Obtém perfil completo do usuário
   */
  async getProfile(userId: string): Promise<Omit<User, 'password'>> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) {
      throw new NotFoundException(`Perfil do usuário "${userId}" não encontrado`);
    }
    return user as any;
  }

  async updateProfile(
    userId: string,
    updateProfileDto: UpdateProfileDto,
  ): Promise<Omit<User, 'password'>> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) {
      throw new NotFoundException(`Usuário com ID "${userId}" não encontrado`);
    }

    if (updateProfileDto.name !== undefined && updateProfileDto.name.trim()) {
      user.name = updateProfileDto.name.trim();
    }
    if (updateProfileDto.phone !== undefined) {
      if (!this.validatePhone(updateProfileDto.phone)) {
        throw new BadRequestException('Telefone deve conter no mínimo 10 dígitos');
      }
      user.phone = updateProfileDto.phone.replace(/\D/g, '');
    }
    if (updateProfileDto.bio !== undefined) {
      user.bio = updateProfileDto.bio;
    }
    if (updateProfileDto.profileImage !== undefined) {
      user.profileImage = updateProfileDto.profileImage;
    }
    if (updateProfileDto.birthDate !== undefined) {
      user.birthDate = updateProfileDto.birthDate;
    }

    user.updatedAt = new Date();
    return user as any;
  }

  /**
   * Lista usuários ativos com paginação
   */
  async listUsers(skip = 0, take = 10): Promise<Omit<User, 'password'>[]> {
    return this.users
      .filter((u) => u.isActive)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(skip, skip + take) as any;
  }
  /**
   * Obtém estatísticas gerais de usuários
   */
  async getUserStats(): Promise<any> {
    const totalUsers = this.users.length;
    const activeUsers = this.users.filter((u) => u.isActive).length;
    const petOwners = this.users.filter((u) => u.role === UserRole.PET_OWNER).length;
    const establishmentOwners = this.users.filter(
      (u) => u.role === UserRole.ESTABLISHMENT_OWNER,
    ).length;

    return {
      totalUsers,
      activeUsers,
      inactiveUsers: totalUsers - activeUsers,
      petOwners,
      establishmentOwners,
      registeredToday: this.users.filter((u) => {
        const today = new Date();
        const userDate = new Date(u.createdAt);
        return userDate.toDateString() === today.toDateString();
      }).length,
    };
  }

  /**
   * Desativa usuário (soft delete)
   */
  async deactivateUser(userId: string): Promise<void> {
    const user = this.users.find((u) => u.id === userId);
    if (!user) {
      throw new NotFoundException(`Usuário com ID "${userId}" não encontrado`);
    }
    user.isActive = false;
    user.updatedAt = new Date();
  }
}
