import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  async findByUser(userId: string) {
    return this.prisma.pet.findMany({ where: { userId }, orderBy: { createdAt: 'desc' } });
  }

  async findById(id: string) {
    const pet = await this.prisma.pet.findUnique({ where: { id } });
    if (!pet) throw new NotFoundException('Pet não encontrado');
    return pet;
  }

  async create(userId: string, data: any) {
    return this.prisma.pet.create({ data: { ...data, userId } });
  }

  async update(id: string, data: any) {
    await this.findById(id);
    return this.prisma.pet.update({ where: { id }, data });
  }

  async remove(id: string) {
    await this.findById(id);
    await this.prisma.pet.delete({ where: { id } });
  }
}
