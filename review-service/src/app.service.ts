import { Injectable, NotFoundException } from '@nestjs/common';
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

  async getAdminStats() {
    const agg = await this.prisma.review.aggregate({
      _avg: { rating: true },
      _count: { id: true },
    });
    return { avgRating: agg._avg.rating ?? 0, totalReviews: agg._count.id };
  }

  // Complaints

  findAllComplaints() {
    return this.prisma.complaint.findMany({ orderBy: { createdAt: 'desc' } });
  }

  findComplaintsByEstab(establishmentId: string) {
    return this.prisma.complaint.findMany({
      where: { establishmentId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createComplaint(data: {
    userId: string;
    userName?: string;
    establishmentId: string;
    establishmentName?: string;
    bookingId?: string;
    subject: string;
    description: string;
    category?: string;
  }) {
    return this.prisma.complaint.create({
      data: {
        userId: data.userId,
        userName: data.userName ?? '',
        establishmentId: data.establishmentId,
        bookingId: data.bookingId ?? null,
        subject: data.subject,
        description: data.description,
        category: data.category ?? '',
        status: 'PENDENTE',
      },
    });
  }

  async resolveComplaint(id: string) {
    await this._findComplaint(id);
    return this.prisma.complaint.update({
      where: { id },
      data: { status: 'RESOLVIDA' },
    });
  }

  async rejectComplaint(id: string) {
    await this._findComplaint(id);
    return this.prisma.complaint.update({
      where: { id },
      data: { status: 'REJEITADA' },
    });
  }

  async respondComplaint(id: string, response: string) {
    await this._findComplaint(id);
    return this.prisma.complaint.update({
      where: { id },
      data: { response, status: 'EM_ANALISE' },
    });
  }

  async deleteComplaint(id: string) {
    await this._findComplaint(id);
    return this.prisma.complaint.delete({ where: { id } });
  }

  private async _findComplaint(id: string) {
    const c = await this.prisma.complaint.findUnique({ where: { id } });
    if (!c) throw new NotFoundException('Reclamação não encontrada');
    return c;
  }
}
