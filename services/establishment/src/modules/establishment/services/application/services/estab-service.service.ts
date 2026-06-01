import { CreateServiceDto } from "@estab/services/application/dto/create-service.dto";
import { EstabServiceDto } from "@estab/services/application/dto/estab-service.dto";
import { EstabService } from "@estab/services/domain/models/estab-service.entity";
import {
  ESTAB_SERVICE_REPOSITORY,
  type EstabServiceRepository,
} from "@estab/services/domain/repositories/estab-service-repository.interface";
import { Inject, Injectable, NotFoundException } from "@nestjs/common";

@Injectable()
export class EstabServiceService {
  constructor(
    @Inject(ESTAB_SERVICE_REPOSITORY)
    private readonly repo: EstabServiceRepository,
  ) {}

  async addService(establishmentId: string, dto: CreateServiceDto): Promise<void> {
    const priceVariable = dto.priceVariable ?? false;
    const service = EstabService.restore({
      establishmentId,
      name: dto.name,
      price: priceVariable ? 0 : (dto.price ?? 0),
      priceVariable,
      durationMinutes: dto.durationMinutes,
      description: dto.description ?? "",
    })!;
    await this.repo.create(service);
  }

  async findByEstablishment(establishmentId: string): Promise<EstabServiceDto[]> {
    const rows = await this.repo.findByEstablishmentId(establishmentId);
    return rows.map((s) => EstabServiceDto.fromService(s)!);
  }

  async removeService(serviceId: string): Promise<void> {
    const service = await this.repo.findById(serviceId);
    if (!service) throw new NotFoundException("Serviço não encontrado");
    await this.repo.delete(serviceId);
  }
}
