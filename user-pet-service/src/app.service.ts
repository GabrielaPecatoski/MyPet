import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  findByUser(userId: string) {
    return this.prisma.pet.findMany({
      where: { userId },
      orderBy: { createdAt: 'asc' },
    });
  }

  async findById(id: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id } });
    if (!pet) throw new NotFoundException('Pet não encontrado');
    return pet;
  }

  create(
    userId: string,
    data: {
      name: string;
      type: string;
      breed?: string;
      age?: number;
      weight?: number;
      imageUrl?: string;
      notes?: string;
    },
  ) {
    return this.prisma.pet.create({
      data: {
        userId,
        name: data.name,
        type: data.type,
        breed: data.breed ?? '',
        age: data.age ?? 0,
        weight: data.weight ?? null,
        imageUrl: data.imageUrl ?? null,
        notes: data.notes ?? null,
      },
    });
  }

  async update(
    id: string,
    data: Partial<{
      name: string;
      type: string;
      breed: string;
      age: number;
      weight: number;
      imageUrl: string;
      notes: string;
    }>,
  ) {
    await this.findById(id);
    return this.prisma.pet.update({ where: { id }, data });
  }

  async remove(id: string) {
    await this.findById(id);
    await this.prisma.pet.delete({ where: { id } });
  }
}
