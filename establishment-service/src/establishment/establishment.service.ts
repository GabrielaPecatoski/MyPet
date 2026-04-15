import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Establishment } from './entities/establishment.entity';
import { EstablishmentServiceItem } from './entities/establishment-service-item.entity';
import { CreateEstablishmentDto } from './dto/create-establishment.dto';
import { UpdateEstablishmentDto } from './dto/update-establishment.dto';
import { CreateServiceDto } from './dto/create-service.dto';

@Injectable()
export class EstablishmentService {
  constructor(
    @InjectRepository(Establishment)
    private readonly repo: Repository<Establishment>,
    @InjectRepository(EstablishmentServiceItem)
    private readonly serviceItemRepo: Repository<EstablishmentServiceItem>,
  ) {}

  findAll(search?: string): Promise<Establishment[]> {
    const qb = this.repo
      .createQueryBuilder('e')
      .leftJoinAndSelect('e.services', 'services');
    if (search) {
      qb.where('LOWER(e.name) LIKE :search', { search: `%${search.toLowerCase()}%` });
    }
    return qb.getMany();
  }

  findByOwner(ownerId: string): Promise<Establishment[]> {
    return this.repo.find({ where: { ownerId }, relations: ['services'] });
  }

  async findById(id: string): Promise<Establishment> {
    const establishment = await this.repo.findOne({ where: { id }, relations: ['services'] });
    if (!establishment) {
      throw new NotFoundException(`Establishment with id "${id}" not found`);
    }
    return establishment;
  }

  create(ownerId: string, dto: CreateEstablishmentDto): Promise<Establishment> {
    const entity = this.repo.create({ ...dto, ownerId, services: [] });
    return this.repo.save(entity);
  }

  async update(id: string, dto: UpdateEstablishmentDto): Promise<Establishment> {
    const establishment = await this.findById(id);
    Object.assign(establishment, dto);
    return this.repo.save(establishment);
  }

  async addService(id: string, dto: CreateServiceDto): Promise<EstablishmentServiceItem> {
    await this.findById(id);
    const serviceItem = this.serviceItemRepo.create({ ...dto, establishmentId: id });
    return this.serviceItemRepo.save(serviceItem);
  }

  async removeService(id: string, serviceId: string): Promise<void> {
    await this.serviceItemRepo.delete({ id: serviceId, establishmentId: id });
  }
}
