import { Injectable } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  findByEstablishment(establishmentId: string) {
    return this.prisma.review.findMany({
      where: { establishmentId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(
    establishmentId: string,
    data: {
      userId: string;
      userName?: string;
      rating: number;
      comment?: string;
    },
  ) {
    const review = await this.prisma.review.create({
      data: {
        establishmentId,
        userId: data.userId,
        userName: data.userName ?? '',
        rating: data.rating,
        comment: data.comment ?? '',
      },
    });
    const agg = await this.prisma.review.aggregate({
      where: { establishmentId },
      _avg: { rating: true },
      _count: { id: true },
    });
    return { review, avg: agg._avg.rating, count: agg._count.id };
  }

  async getStats(establishmentId: string) {
    const agg = await this.prisma.review.aggregate({
      where: { establishmentId },
      _avg: { rating: true },
      _count: { id: true },
    });
    return { avg: agg._avg.rating ?? 0, count: agg._count.id };
  }
}
