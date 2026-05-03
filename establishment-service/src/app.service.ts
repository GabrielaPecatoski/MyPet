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

  async create(ownerId: string, data: any) {
    const { services, ...estabData } = data;
    return this.prisma.establishment.create({
      data: {
        ...estabData,
        ownerId,
        rating: 0,
        reviewCount: 0,
        services: services?.length ? { create: services } : undefined,
      },
      include: { services: true },
    });
  }

  async update(id: string, data: any) {
    await this.findById(id);
    return this.prisma.establishment.update({
      where: { id },
      data,
      include: { services: true },
    });
  }

  async addService(establishmentId: string, service: { name: string; price: number; durationMinutes: number; description?: string }) {
    await this.findById(establishmentId);
    await this.prisma.service.create({ data: { ...service, establishmentId } });
    return this.findById(establishmentId);
  }

  async removeService(establishmentId: string, serviceId: string) {
    await this.findById(establishmentId);
    await this.prisma.service.delete({ where: { id: serviceId } }).catch(() => {
      throw new NotFoundException('Serviço não encontrado');
    });
    return this.findById(establishmentId);
  }

  async findAllAdmin() {
    const establishments = await this.prisma.establishment.findMany({
      include: { _count: { select: { services: true } } },
    });
    return establishments.map((e) => ({
      id: e.id,
      name: e.name,
      type: e.type,
      address: e.address,
      phone: e.phone,
      rating: e.rating,
      servicesCount: e._count.services,
      bookingsCount: 0,
    }));
  }

  async getStats(estabId: string) {
    const estab = await this.findById(estabId);
    const monthNames = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun'];
    const baseValues = [1800, 2400, 2100, 3000, 2700, 3200];
    return {
      totalRevenue: 18500.0,
      monthRevenue: 3200.0,
      avgTicket: 85.0,
      totalBookings: 217,
      monthBookings: 38,
      avgRating: estab.rating,
      totalReviews: estab.reviewCount,
      last6Months: monthNames.map((month, i) => ({ month, value: baseValues[i] })),
      topServices: estab.services.slice(0, 3).map((s, i) => ({ name: s.name, count: 30 - i * 5 })),
    };
  }

  async getAdminStats() {
    const [total, establishments] = await Promise.all([
      this.prisma.establishment.count(),
      this.prisma.establishment.findMany({ select: { rating: true } }),
    ]);
    const avgRating =
      establishments.length > 0
        ? establishments.reduce((s, e) => s + e.rating, 0) / establishments.length
        : 0;
    return {
      totalUsers: 150,
      totalEstabs: total,
      totalBookings: 1240,
      avgRating: parseFloat(avgRating.toFixed(1)),
      bookingsByMonth: [
        { month: 'Jan', count: 180 },
        { month: 'Fev', count: 210 },
        { month: 'Mar', count: 195 },
        { month: 'Abr', count: 230 },
        { month: 'Mai', count: 245 },
        { month: 'Jun', count: 180 },
      ],
      serviceDistribution: [
        { label: 'Banho & Tosa', percentage: 45 },
        { label: 'Veterinário', percentage: 30 },
        { label: 'Hotel', percentage: 15 },
        { label: 'Outros', percentage: 10 },
      ],
      avgTicket: 92.5,
      clientRetention: 68.5,
      nps: 72,
      monthlyGrowth: 12.3,
    };
  }
}
