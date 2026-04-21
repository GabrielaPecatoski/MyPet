import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(private readonly prisma: PrismaService) {}

  async create(data: {
    userId: string;
    title: string;
    body: string;
    type: string;
  }) {
    this.logger.log(`[NOTIF] → ${data.userId}: ${data.title}`);
    return this.prisma.notification.create({
      data: {
        userId: data.userId,
        title: data.title,
        body: data.body,
        type: data.type,
      },
    });
  }

  getByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markRead(id: string) {
    return this.prisma.notification.update({
      where: { id },
      data: { read: true },
    });
  }

  async markAllRead(userId: string) {
    await this.prisma.notification.updateMany({
      where: { userId, read: false },
      data: { read: true },
    });
  }

  async countUnread(userId: string) {
    return this.prisma.notification.count({ where: { userId, read: false } });
  }

  async sendBookingConfirmation(data: {
    bookingId: string;
    userId: string;
    establishmentId: string;
    scheduledAt: string;
  }) {
    await this.create({
      userId: data.establishmentId,
      title: 'Novo Agendamento',
      body: `Um novo agendamento foi solicitado para ${new Date(data.scheduledAt).toLocaleDateString('pt-BR')}.`,
      type: 'NEW_BOOKING',
    });
  }

  async sendStatusUpdate(data: {
    bookingId: string;
    userId: string;
    status: string;
    scheduledAt?: string;
  }) {
    if (data.status === 'CONFIRMADO') {
      await this.create({
        userId: data.userId,
        title: 'Agendamento Confirmado!',
        body: `Seu agendamento foi confirmado${data.scheduledAt ? ' para ' + new Date(data.scheduledAt).toLocaleDateString('pt-BR') : ''}.`,
        type: 'BOOKING_CONFIRMED',
      });
    } else if (data.status === 'RECUSADO') {
      await this.create({
        userId: data.userId,
        title: 'Agendamento Recusado',
        body: 'Infelizmente seu agendamento foi recusado pelo estabelecimento.',
        type: 'BOOKING_REJECTED',
      });
    }
  }

  async sendCompletionNotification(data: {
    bookingId: string;
    userId: string;
    completedAt: string;
  }) {
    await this.create({
      userId: data.userId,
      title: 'Atendimento Concluído!',
      body: 'Seu pet foi atendido! Que tal deixar uma avaliação?',
      type: 'BOOKING_COMPLETED',
    });
  }
}
