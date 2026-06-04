import { CreateVeterinarianDto } from '@estab/veterinarians/application/dto/create-veterinarian.dto';
import { VeterinarianDto } from '@estab/veterinarians/application/dto/veterinarian.dto';
import { Veterinarian } from '@estab/veterinarians/domain/models/veterinarian.entity';
import {
  VETERINARIAN_REPOSITORY,
  type VeterinarianRepository,
} from '@estab/veterinarians/domain/repositories/veterinarian-repository.interface';
import { ConflictException, Inject, Injectable, NotFoundException } from '@nestjs/common';

@Injectable()
export class VeterinarianService {
  constructor(
    @Inject(VETERINARIAN_REPOSITORY)
    private readonly repo: VeterinarianRepository,
  ) {}

  async register(dto: CreateVeterinarianDto): Promise<VeterinarianDto> {
    const byCpf = await this.repo.findByCpf(dto.cpf);
    if (byCpf) throw new ConflictException('CPF já cadastrado como veterinário');

    const vet = Veterinarian.restore({
      establishmentId: dto.establishmentId,
      name: dto.name,
      phone: dto.phone,
      cpf: dto.cpf,
      crmv: dto.crmv,
      especialidade: dto.especialidade,
      status: 'ATIVO',
    })!;

    const created = await this.repo.create(vet);
    return VeterinarianDto.fromVet(created)!;
  }

  async findAll(): Promise<VeterinarianDto[]> {
    const rows = await this.repo.findAll();
    return rows.map((v) => VeterinarianDto.fromVet(v)!);
  }

  async findByEstablishment(establishmentId: string): Promise<VeterinarianDto[]> {
    const rows = await this.repo.findByEstablishment(establishmentId);
    return rows.map((v) => VeterinarianDto.fromVet(v)!);
  }

  async findUnassociated(): Promise<VeterinarianDto[]> {
    const rows = await this.repo.findUnassociated();
    return rows.map((v) => VeterinarianDto.fromVet(v)!);
  }

  async findByCpf(cpf: string): Promise<VeterinarianDto | null> {
    return VeterinarianDto.fromVet(await this.repo.findByCpf(cpf));
  }

  async findById(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException('Veterinário não encontrado');
    return VeterinarianDto.fromVet(vet)!;
  }

  async associate(id: string, establishmentId: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException('Veterinário não encontrado');
    if (vet.establishmentId) {
      throw new ConflictException('Veterinário já está associado a um estabelecimento');
    }
    vet.withEstablishment(establishmentId);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async dissociate(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException('Veterinário não encontrado');
    vet.withEstablishment(undefined);
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async deactivate(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException('Veterinário não encontrado');
    vet.withStatus('INATIVO');
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async activate(id: string): Promise<VeterinarianDto> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException('Veterinário não encontrado');
    vet.withStatus('ATIVO');
    await this.repo.update(vet);
    return VeterinarianDto.fromVet(vet)!;
  }

  async remove(id: string): Promise<void> {
    const vet = await this.repo.findById(id);
    if (!vet) throw new NotFoundException('Veterinário não encontrado');
    await this.repo.delete(id);
  }
}
