import { CreateEstablishmentDto } from "@estab/establishments/application/dto/create-establishment.dto";
import { EstablishmentDto } from "@estab/establishments/application/dto/establishment.dto";
import { UpdateEstablishmentDto } from "@estab/establishments/application/dto/update-establishment.dto";
import { Establishment } from "@estab/establishments/domain/models/establishment.entity";
import {
  ESTABLISHMENT_REPOSITORY,
  type EstablishmentAdminItem,
  type EstablishmentRepository,
} from "@estab/establishments/domain/repositories/establishment-repository.interface";
import { Inject, Injectable, NotFoundException } from "@nestjs/common";
import type { PaginatedResult, PaginationParams } from "@shared/infra/hateoas";

@Injectable()
export class EstablishmentService {
  constructor(
    @Inject(ESTABLISHMENT_REPOSITORY)
    private readonly repo: EstablishmentRepository,
  ) {}

  async create(
    ownerId: string,
    dto: CreateEstablishmentDto,
  ): Promise<EstablishmentDto> {
    const establishment = Establishment.restore({
      ownerId,
      name: dto.name,
      description: dto.description,
      address: dto.address,
      city: dto.city,
      phone: dto.phone,
      type: dto.type,
      rating: 0,
      reviewCount: 0,
      imageUrl: dto.imageUrl,
      crmv: dto.crmv,
      atendeEmergencia: dto.atendeEmergencia ?? false,
      atendimento24h: dto.atendimento24h ?? false,
      receberAlertaSonoro: dto.receberAlertaSonoro ?? false,
      receberPushEmergencia: dto.receberPushEmergencia ?? false,
    })!;
    const created = await this.repo.create(establishment);
    return EstablishmentDto.fromEstablishment(created)!;
  }

  async findAll(search?: string): Promise<EstablishmentDto[]> {
    const rows = await this.repo.findAll(search);
    return rows.map((e) => EstablishmentDto.fromEstablishment(e)!);
  }

  async listPaginated(
    params: PaginationParams,
    search?: string,
  ): Promise<PaginatedResult<EstablishmentDto>> {
    const { rows, total } = await this.repo.findAllPaginated(params, search);
    return {
      data: rows.map((e) => EstablishmentDto.fromEstablishment(e)!),
      total,
      page: params.page,
      limit: params.limit,
    };
  }

  async findAllAdmin(): Promise<EstablishmentAdminItem[]> {
    return this.repo.findAllAdmin();
  }

  async findByOwnerId(ownerId: string): Promise<EstablishmentDto[]> {
    const rows = await this.repo.findByOwnerId(ownerId);
    return rows.map((e) => EstablishmentDto.fromEstablishment(e)!);
  }

  async findById(id: string): Promise<EstablishmentDto | null> {
    const e = await this.repo.findById(id);
    return EstablishmentDto.fromEstablishment(e);
  }

  async findByEmergency(): Promise<EstablishmentDto[]> {
    const rows = await this.repo.findByEmergency();
    return rows.map((e) => EstablishmentDto.fromEstablishment(e)!);
  }

  async update(id: string, dto: UpdateEstablishmentDto): Promise<void> {
    const e = await this.repo.findById(id);
    if (!e) throw new NotFoundException("Estabelecimento não encontrado");
    if (dto.name) e.withName(dto.name);
    if (dto.description) e.withDescription(dto.description);
    if (dto.address) e.withAddress(dto.address);
    if (dto.city) e.withCity(dto.city);
    if (dto.phone) e.withPhone(dto.phone);
    if (dto.type) e.withType(dto.type);
    if (dto.imageUrl !== undefined) e.withImageUrl(dto.imageUrl);
    if (dto.crmv !== undefined) e.withCrmv(dto.crmv);
    if (dto.atendeEmergencia !== undefined)
      e.withAtendeEmergencia(dto.atendeEmergencia);
    if (dto.atendimento24h !== undefined)
      e.withAtendimento24h(dto.atendimento24h);
    if (dto.receberAlertaSonoro !== undefined)
      e.withReceberAlertaSonoro(dto.receberAlertaSonoro);
    if (dto.receberPushEmergencia !== undefined)
      e.withReceberPushEmergencia(dto.receberPushEmergencia);
    await this.repo.update(e);
  }

  async updateRating(
    id: string,
    rating: number,
    reviewCount: number,
  ): Promise<void> {
    await this.repo.updateRating(id, rating, reviewCount);
  }

  async remove(id: string): Promise<void> {
    const e = await this.repo.findById(id);
    if (!e) throw new NotFoundException("Estabelecimento não encontrado");
    await this.repo.delete(id);
  }
}
