import { Injectable, NotFoundException } from '@nestjs/common';
import * as http from 'http';
import { PrismaService } from './prisma.service';

function httpGetJson(url: string): Promise<any> {
  return new Promise((resolve, reject) => {
    const u = new URL(url);
    const req = http.get(
      {
        hostname: u.hostname,
        port: Number(u.port) || 80,
        path: u.pathname + u.search,
        method: 'GET',
      },
      (res) => {
        let data = '';
        res.on('data', (chunk) => { data += chunk; });
        res.on('end', () => {
          try { resolve(JSON.parse(data)); }
          catch { reject(new Error('Invalid JSON')); }
        });
      },
    );
    req.on('error', reject);
    req.end();
  });
}

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

  async remove(id: string) {
    await this.findById(id);
    await this.prisma.establishment.delete({ where: { id } });
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

  async getStats(establishmentId: string) {
    const bookingUrl =
      process.env.BOOKING_SERVICE_URL ?? 'http://localhost:3005';
    const reviewUrl =
      process.env.REVIEW_SERVICE_URL ?? 'http://localhost:3007';

    const emptyBookingStats = {
      totalBookings: 0,
      monthBookings: 0,
      totalRevenue: 0,
      monthRevenue: 0,
      avgTicket: 0,
      last6Months: [],
      topServices: [],
    };

    const [bookingStats, reviewStats] = await Promise.all([
      httpGetJson(
        `${bookingUrl}/bookings/stats/establishment/${establishmentId}`,
      ).catch(() => emptyBookingStats),
      httpGetJson(
        `${reviewUrl}/reviews/establishment/${establishmentId}/stats`,
      ).catch(() => ({ avg: 0, count: 0 })),
    ]);

    return {
      ...bookingStats,
      avgRating: (reviewStats as any).avg ?? 0,
      totalReviews: (reviewStats as any).count ?? 0,
    };
  }
}
