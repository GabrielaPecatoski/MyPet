import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { v4 as uuidv4 } from 'uuid';
import { CreateRegistrationDto } from './dto/create-registration.dto';
import { UpdateRegistrationDto } from './dto/update-registration.dto';
import { Registration, RegistrationStatus } from './entities/registration.entity';

@Injectable()
export class RegistrationService {
  private registrations: Registration[] = [];

  /**
   * Validações internas
   */
  private validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  private validateCnpj(cnpj: string): boolean {
    const cleanCnpj = cnpj.replace(/\D/g, '');
    return cleanCnpj.length === 14;
  }

  private validatePhone(phone: string): boolean {
    const cleanPhone = phone.replace(/\D/g, '');
    return cleanPhone.length >= 10;
  }

  /**
   * Cria novo registro de estabelecimento
   */
  async create(createRegistrationDto: CreateRegistrationDto): Promise<Registration> {
    // Validar entrada
    if (!createRegistrationDto.name || createRegistrationDto.name.trim().length === 0) {
      throw new BadRequestException('Nome é obrigatório');
    }
    if (!this.validateEmail(createRegistrationDto.email)) {
      throw new BadRequestException('Email inválido');
    }
    if (createRegistrationDto.cnpj && !this.validateCnpj(createRegistrationDto.cnpj)) {
      throw new BadRequestException('CNPJ deve conter 14 dígitos');
    }
    if (!this.validatePhone(createRegistrationDto.phone)) {
      throw new BadRequestException('Telefone deve conter no mínimo 10 dígitos');
    }

    // Validar duplicatas de email
    const existingByEmail = this.registrations.find(
      (reg) => reg.email === createRegistrationDto.email.toLowerCase(),
    );
    if (existingByEmail) {
      throw new ConflictException('Email já registrado no sistema');
    }

    // Validar duplicatas de CNPJ
    if (createRegistrationDto.cnpj) {
      const cleanCnpj = createRegistrationDto.cnpj.replace(/\D/g, '');
      const existingByCnpj = this.registrations.find((reg) => reg.cnpj === cleanCnpj);
      if (existingByCnpj) {
        throw new ConflictException('CNPJ já registrado no sistema');
      }
    }

    const registration = new Registration({
      id: uuidv4(),
      name: createRegistrationDto.name.trim(),
      email: createRegistrationDto.email.toLowerCase().trim(),
      cnpj: createRegistrationDto.cnpj?.replace(/\D/g, '') || '',
      phone: createRegistrationDto.phone.replace(/\D/g, ''),
      address: createRegistrationDto.address?.trim() || '',
      city: createRegistrationDto.city?.trim() || '',
      state: createRegistrationDto.state?.toUpperCase().trim() || '',
      zipCode: createRegistrationDto.zipCode?.replace(/\D/g, '') || '',
      status: RegistrationStatus.PENDING,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    this.registrations.push(registration);
    return registration;
  }

  /**
   * Lista todos os registros
   */
  async findAll(skip = 0, take = 10): Promise<Registration[]> {
    return this.registrations
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(skip, skip + take);
  }

  /**
   * Busca registro por ID
   */
  async findOne(id: string): Promise<Registration> {
    const registration = this.registrations.find((reg) => reg.id === id);
    if (!registration) {
      throw new NotFoundException(`Registro com ID "${id}" não encontrado`);
    }
    return registration;
  }

  /**
   * Busca registro por email
   */
  async findByEmail(email: string): Promise<Registration | undefined> {
    return this.registrations.find((reg) => reg.email === email.toLowerCase());
  }

  /**
   * Busca registro por CNPJ
   */
  async findByCnpj(cnpj: string): Promise<Registration | undefined> {
    const cleanCnpj = cnpj.replace(/\D/g, '');
    return this.registrations.find((reg) => reg.cnpj === cleanCnpj);
  }

  /**
   * Busca registros por status
   */
  async findByStatus(status: RegistrationStatus, skip = 0, take = 10): Promise<Registration[]> {
    return this.registrations
      .filter((reg) => reg.status === status)
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(skip, skip + take);
  }

  /**
   * Atualiza registro
   */
  async update(
    id: string,
    updateRegistrationDto: UpdateRegistrationDto,
  ): Promise<Registration> {
    const registration = await this.findOne(id);

    // Validar email único se for alterado
    if (
      updateRegistrationDto.email &&
      updateRegistrationDto.email !== registration.email
    ) {
      if (!this.validateEmail(updateRegistrationDto.email)) {
        throw new BadRequestException('Email inválido');
      }
      const existingByEmail = this.registrations.find(
        (reg) => reg.email === updateRegistrationDto.email.toLowerCase() && reg.id !== id,
      );
      if (existingByEmail) {
        throw new ConflictException('Email já registrado no sistema');
      }
    }

    // Validar CNPJ único se for alterado
    if (
      updateRegistrationDto.cnpj &&
      updateRegistrationDto.cnpj !== registration.cnpj
    ) {
      if (!this.validateCnpj(updateRegistrationDto.cnpj)) {
        throw new BadRequestException('CNPJ deve conter 14 dígitos');
      }
      const cleanCnpj = updateRegistrationDto.cnpj.replace(/\D/g, '');
      const existingByCnpj = this.registrations.find(
        (reg) => reg.cnpj === cleanCnpj && reg.id !== id,
      );
      if (existingByCnpj) {
        throw new ConflictException('CNPJ já registrado no sistema');
      }
    }

    // Validar telefone se for alterado
    if (updateRegistrationDto.phone && !this.validatePhone(updateRegistrationDto.phone)) {
      throw new BadRequestException('Telefone deve conter no mínimo 10 dígitos');
    }

    // Atualizar apenas campos permitidos
    if (updateRegistrationDto.name) registration.name = updateRegistrationDto.name.trim();
    if (updateRegistrationDto.email)
      registration.email = updateRegistrationDto.email.toLowerCase().trim();
    if (updateRegistrationDto.cnpj) registration.cnpj = updateRegistrationDto.cnpj.replace(/\D/g, '');
    if (updateRegistrationDto.phone) registration.phone = updateRegistrationDto.phone.replace(/\D/g, '');
    if (updateRegistrationDto.address) registration.address = updateRegistrationDto.address.trim();
    if (updateRegistrationDto.city) registration.city = updateRegistrationDto.city.trim();
    if (updateRegistrationDto.state)
      registration.state = updateRegistrationDto.state.toUpperCase().trim();
    if (updateRegistrationDto.zipCode)
      registration.zipCode = updateRegistrationDto.zipCode.replace(/\D/g, '');

    registration.updatedAt = new Date();
    return registration;
  }

  /**
   * Remove registro
   */
  async remove(id: string): Promise<{ message: string }> {
    const index = this.registrations.findIndex((reg) => reg.id === id);
    if (index === -1) {
      throw new NotFoundException(`Registro com ID "${id}" não encontrado`);
    }

    this.registrations.splice(index, 1);
    return { message: 'Registro removido com sucesso' };
  }

  /**
   * Atualiza status do registro
   */
  async updateStatus(
    id: string,
    status: RegistrationStatus,
  ): Promise<Registration> {
    const registration = await this.findOne(id);

    // Validar status válido
    const validStatuses = Object.values(RegistrationStatus);
    if (!validStatuses.includes(status)) {
      throw new BadRequestException(`Status inválido. Estatuses válidos: ${validStatuses.join(', ')}`);
    }

    registration.status = status;
    registration.updatedAt = new Date();
    return registration;
  }

  /**
   * Obtém estatísticas de registros
   */
  async getStats(): Promise<any> {
    return {
      total: this.registrations.length,
      pending: this.registrations.filter((r) => r.status === RegistrationStatus.PENDING).length,
      approved: this.registrations.filter((r) => r.status === RegistrationStatus.APPROVED).length,
      rejected: this.registrations.filter((r) => r.status === RegistrationStatus.REJECTED).length,
      inactive: this.registrations.filter((r) => r.status === RegistrationStatus.INACTIVE).length,
    };
  }
}
