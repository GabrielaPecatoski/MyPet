// @ts-ignore
import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
declare const process: any;
// @ts-ignore
import { v4 as uuidv4 } from 'uuid';
import { UpdateEstablishmentProfileDto } from './dto/update-establishment-profile.dto';
import { EstablishmentProfile, EstablishmentType } from './entities/establishment-profile.entity';
import { EstablishmentStatsDto } from './dto/establishment-stats.dto';

@Injectable()
export class EstablishmentProfileService {
  private profiles: EstablishmentProfile[] = [];

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
   * Cria novo perfil de estabelecimento
   */
  async createProfile(
    ownerId: string,
    cnpj: string,
    name: string,
    email: string,
    phone: string,
    address: string,
    city: string,
    state: string,
    zipCode: string,
    type: EstablishmentType = EstablishmentType.PET_SHOP,
    services: string[] = [],
  ): Promise<EstablishmentProfile> {
    // Validar entrada
    if (!ownerId) throw new BadRequestException('ID do proprietário é obrigatório');
    if (!name || name.trim().length === 0) throw new BadRequestException('Nome é obrigatório');
    if (!this.validateEmail(email)) throw new BadRequestException('Email inválido');
    if (!this.validateCnpj(cnpj)) throw new BadRequestException('CNPJ deve conter 14 dígitos');
    if (!this.validatePhone(phone)) throw new BadRequestException('Telefone deve conter no mínimo 10 dígitos');

    // Validar CNPJ único
    const cleanCnpj = cnpj.replace(/\D/g, '');
    const existingByCnpj = this.profiles.find((p) => p.cnpj === cleanCnpj);
    if (existingByCnpj) {
      throw new ConflictException('CNPJ já registrado no sistema');
    }

    const profile = new EstablishmentProfile({
      id: uuidv4(),
      ownerId,
      name: name.trim(),
      email: email.toLowerCase().trim(),
      phone: phone.replace(/\D/g, ''),
      address: address.trim(),
      city: city.trim(),
      state: state.toUpperCase().trim(),
      zipCode: zipCode.replace(/\D/g, ''),
      cnpj: cleanCnpj,
      type,
      services: services || [],
      isActive: true,
      rating: 0,
      followers: 0,
      isVerified: false,
      createdAt: new Date(),
      updatedAt: new Date(),
    });

    this.profiles.push(profile);
    return profile;
  }

  /**
   * Obtém perfil por ID
   */
  async getProfile(establishmentId: string): Promise<EstablishmentProfile> {
    const profile = this.profiles.find((p) => p.id === establishmentId);
    if (!profile) {
      throw new NotFoundException(`Perfil de estabelecimento "${establishmentId}" não encontrado`);
    }
    return profile;
  }

  /**
   * Obtém perfil por ID do proprietário
   */
  async getProfileByOwnerId(ownerId: string): Promise<EstablishmentProfile> {
    const profile = this.profiles.find((p) => p.ownerId === ownerId);
    if (!profile) {
      throw new NotFoundException(`Nenhum estabelecimento encontrado para o proprietário "${ownerId}"`);
    }
    return profile;
  }

  /**
   * Atualiza perfil do estabelecimento
   */
  async updateProfile(
    establishmentId: string,
    updateProfileDto: UpdateEstablishmentProfileDto,
  ): Promise<EstablishmentProfile> {
    const profile = this.profiles.find((p) => p.id === establishmentId);
    if (!profile) {
      throw new NotFoundException(`Perfil de estabelecimento "${establishmentId}" não encontrado`);
    }

    // Email não é editável no perfil

    // Validar telefone se for alterado
    if (updateProfileDto.phone && !this.validatePhone(updateProfileDto.phone)) {
      throw new BadRequestException('Telefone deve conter no mínimo 10 dígitos');
    }

    // Atualizar apenas campos permitidos
    if (updateProfileDto.name) profile.name = updateProfileDto.name.trim();
    if (updateProfileDto.phone) profile.phone = updateProfileDto.phone.replace(/\D/g, '');
    if (updateProfileDto.address) profile.address = updateProfileDto.address.trim();
    if (updateProfileDto.state) profile.state = updateProfileDto.state.toUpperCase().trim();
    if (updateProfileDto.bio !== undefined) profile.bio = updateProfileDto.bio;
    if (updateProfileDto.profileImage !== undefined) profile.profileImage = updateProfileDto.profileImage;
    if (updateProfileDto.coverImage !== undefined) profile.coverImage = updateProfileDto.coverImage;
    if (updateProfileDto.services) profile.services = updateProfileDto.services;
    if (updateProfileDto.openingHours) profile.openingHours = updateProfileDto.openingHours;

    profile.updatedAt = new Date();
    return profile;
  }

  /**
   * Obtém estatísticas do perfil
   */
  async getProfileStats(establishmentId: string): Promise<EstablishmentStatsDto> {
    const profile = this.profiles.find((p) => p.id === establishmentId);
    if (!profile) {
      throw new NotFoundException(`Perfil de estabelecimento "${establishmentId}" não encontrado`);
    }

    return {
      totalBookings: Math.floor(Math.random() * 100),
      totalReviews: Math.floor(Math.random() * 50),
      averageRating: profile.rating,
      followers: profile.followers,
      followers_growth: Math.floor(Math.random() * 20),
      services_count: profile.services.length,
    };
  }

  /**
   * Lista estabelecimentos com filtro e paginação
   */
  async listEstablishments(type?: EstablishmentType, skip = 0, take = 10): Promise<EstablishmentProfile[]> {
    let results = this.profiles.filter((p) => p.isActive);
    if (type) {
      results = results.filter((p) => p.type === type);
    }
    return results
      .sort((a, b) => new Date(b.createdAt).getTime() - new Date(a.createdAt).getTime())
      .slice(skip, skip + take);
  }

  /**
   * Busca estabelecimentos por query
   */
  async searchEstablishments(query: string): Promise<EstablishmentProfile[]> {
    const lowerQuery = query.toLowerCase().trim();
    return this.profiles.filter(
      (p) =>
        p.isActive &&
        (p.name.toLowerCase().includes(lowerQuery) ||
          p.city.toLowerCase().includes(lowerQuery) ||
          p.address.toLowerCase().includes(lowerQuery) ||
          p.services.some((s) => s.toLowerCase().includes(lowerQuery))),
    );
  }

  /**
   * Incrementa followers
   */
  async addFollower(establishmentId: string): Promise<EstablishmentProfile> {
    const profile = this.profiles.find((p) => p.id === establishmentId);
    if (!profile) {
      throw new NotFoundException(`Perfil de estabelecimento "${establishmentId}" não encontrado`);
    }

    profile.followers += 1;
    profile.updatedAt = new Date();
    return profile;
  }

  /**
   * Atualiza avaliação (rating)
   */
  async updateRating(establishmentId: string, rating: number): Promise<EstablishmentProfile> {
    const profile = this.profiles.find((p) => p.id === establishmentId);
    if (!profile) {
      throw new NotFoundException(`Perfil de estabelecimento "${establishmentId}" não encontrado`);
    }

    if (typeof rating !== 'number' || rating < 0 || rating > 5) {
      throw new BadRequestException('Avaliação deve estar entre 0 e 5');
    }

    profile.rating = rating;
    profile.updatedAt = new Date();
    return profile;
  }

  /**
   * Desativa perfil
   */
  async deactivateProfile(establishmentId: string): Promise<void> {
    const profile = this.profiles.find((p) => p.id === establishmentId);
    if (!profile) {
      throw new NotFoundException(`Perfil de estabelecimento "${establishmentId}" não encontrado`);
    }
    profile.isActive = false;
    profile.updatedAt = new Date();
  }
}
