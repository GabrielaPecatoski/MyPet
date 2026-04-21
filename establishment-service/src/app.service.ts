import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  async findAll(search?: string) {
    return this.prisma.establishment.findMany({
      where: search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { city: { contains: search, mode: 'insensitive' } },
            ],
          }
        : undefined,
      include: { services: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async findById(id: string) {
    const e = await this.prisma.establishment.findUnique({
      where: { id },
      include: { services: true },
    });
    if (!e) throw new NotFoundException('Estabelecimento não encontrado');
    return e;
  }

  async findByOwner(ownerId: string) {
    return this.prisma.establishment.findMany({
      where: { ownerId },
      include: { services: true },
    });
  }

  async create(
    ownerId: string,
    data: {
      name?: string;
      description?: string;
      address?: string;
      city?: string;
      phone?: string;
      type?: string;
      imageUrl?: string | null;
    },
  ) {
    return this.prisma.establishment.create({
      data: {
        ownerId,
        name: data.name ?? '',
        description: data.description ?? '',
        address: data.address ?? '',
        city: data.city ?? '',
        phone: data.phone ?? '',
        type: data.type ?? 'PET_SHOP',
        imageUrl: data.imageUrl ?? null,
      },
      include: { services: true },
    });
  }

  async update(
    id: string,
    data: {
      name?: string;
      description?: string;
      address?: string;
      city?: string;
      phone?: string;
      type?: string;
      imageUrl?: string | null;
      rating?: number;
      reviewCount?: number;
    },
  ) {
    await this.findById(id);
    return this.prisma.establishment.update({
      where: { id },
      data: {
        ...(data.name !== undefined && { name: data.name }),
        ...(data.description !== undefined && {
          description: data.description,
        }),
        ...(data.address !== undefined && { address: data.address }),
        ...(data.city !== undefined && { city: data.city }),
        ...(data.phone !== undefined && { phone: data.phone }),
        ...(data.type !== undefined && { type: data.type }),
        ...(data.imageUrl !== undefined && { imageUrl: data.imageUrl }),
        ...(data.rating !== undefined && { rating: data.rating }),
        ...(data.reviewCount !== undefined && {
          reviewCount: data.reviewCount,
        }),
      },
      include: { services: true },
    });
  }

  async addService(
    establishmentId: string,
    service: {
      name: string;
      price: number;
      durationMinutes: number;
      description?: string;
    },
  ) {
    await this.findById(establishmentId);
    return this.prisma.establishment.update({
      where: { id: establishmentId },
      data: {
        services: {
          create: {
            name: service.name,
            price: service.price,
            durationMinutes: service.durationMinutes,
            description: service.description ?? null,
          },
        },
      },
      include: { services: true },
    });
  }

  async removeService(establishmentId: string, serviceId: string) {
    await this.findById(establishmentId);
    await this.prisma.service.delete({ where: { id: serviceId } });
    return this.findById(establishmentId);
  }
}
