import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { PrismaService } from './prisma.service';
import { RABBITMQ_CLIENT } from './constants';
import { EVENTS } from './events/events.constants';

@Injectable()
export class AppService {
  private readonly logger = new Logger(AppService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(RABBITMQ_CLIENT) private readonly rabbitClient: ClientProxy,
  ) {}

  async getByEstablishment(establishmentId: string) {
    return this.prisma.review.findMany({
      where: { establishmentId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createReview(data: {
    userId: string;
    userName?: string;
    establishmentId: string;
    bookingId?: string;
    rating: number;
    comment?: string;
  }) {
    const review = await this.prisma.review.create({
      data: {
        userId: data.userId,
        userName: data.userName ?? '',
        establishmentId: data.establishmentId,
        rating: data.rating,
        comment: data.comment ?? '',
      },
    });

    try {
      this.rabbitClient.emit(EVENTS.REVIEW_CREATED, {
        reviewId: review.id,
        userId: review.userId,
        establishmentId: review.establishmentId,
        rating: review.rating,
        createdAt: review.createdAt.toISOString(),
      });
    } catch (err) {
      this.logger.warn(`Falha ao emitir REVIEW_CREATED: ${err}`);
    }

    return review;
  }

  async getComplaintsByEstab(establishmentId: string) {
    return this.prisma.complaint.findMany({
      where: { establishmentId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getAllComplaints() {
    return this.prisma.complaint.findMany({ orderBy: { createdAt: 'desc' } });
  }

  async createComplaint(data: {
    userId: string;
    userName?: string;
    establishmentId: string;
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
        bookingId: data.bookingId,
        subject: data.subject,
        description: data.description,
        category: data.category ?? '',
        status: 'PENDENTE',
      },
    });
  }

  async respondComplaint(id: string, response: string) {
    const c = await this.prisma.complaint.findUnique({ where: { id } });
    if (!c) throw new NotFoundException('Reclamação não encontrada');
    return this.prisma.complaint.update({
      where: { id },
      data: { response, status: 'RESPONDIDO' },
    });
  }

  async resolveComplaint(id: string) {
    const c = await this.prisma.complaint.findUnique({ where: { id } });
    if (!c) throw new NotFoundException('Reclamação não encontrada');
    return this.prisma.complaint.update({ where: { id }, data: { status: 'RESOLVIDO' } });
  }

  async deleteComplaint(id: string) {
    const c = await this.prisma.complaint.findUnique({ where: { id } });
    if (!c) throw new NotFoundException('Reclamação não encontrada');
    await this.prisma.complaint.delete({ where: { id } });
  }
}
