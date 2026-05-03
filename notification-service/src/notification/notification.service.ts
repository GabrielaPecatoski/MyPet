import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../prisma.service';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  constructor(private readonly prisma: PrismaService) {}

  private async save(userId: string, title: string, body: string, type: string) {
    try {
      await this.prisma.notification.create({ data: { userId, title, body, type } });
    } catch (err) {
      this.logger.warn(`Falha ao salvar notificação: ${err}`);
    }
  }

  async getByUser(userId: string) {
    return this.prisma.notification.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  async markRead(id: string) {
    return this.prisma.notification.update({ where: { id }, data: { read: true } });
  }

  async sendBookingConfirmation(data: {
    bookingId: string; userId: string; establishmentId: string; scheduledAt: string;
  }) {
    const title = 'Agendamento recebido';
    const body = 'Seu agendamento foi recebido e está pendente de confirmação.';
    this.logger.log(`[NOTIF] ${title} — booking: ${data.bookingId}`);
    await this.save(data.userId, title, body, 'BOOKING_CREATED');
  }

  async sendStatusUpdate(data: {
    bookingId: string; status: 'CONFIRMADO' | 'RECUSADO'; updatedAt: string;
  }) {
    const title = data.status === 'CONFIRMADO' ? 'Agendamento confirmado!' : 'Agendamento recusado';
    const body = data.status === 'CONFIRMADO'
      ? 'Seu agendamento foi confirmado pelo estabelecimento.'
      : 'Seu agendamento foi recusado. Entre em contato com o estabelecimento.';
    this.logger.log(`[NOTIF] ${title} — booking: ${data.bookingId}`);
    await this.save('unknown', title, body, 'BOOKING_STATUS_UPDATED');
  }

  async sendCompletionNotification(data: { bookingId: string; completedAt: string }) {
    const title = 'Atendimento finalizado!';
    const body = 'Seu pet foi atendido! Que tal deixar uma avaliação?';
    this.logger.log(`[NOTIF] ${title} — booking: ${data.bookingId}`);
    await this.save('unknown', title, body, 'BOOKING_COMPLETED');
  }

  async sendReviewNotification(data: {
    reviewId: string; userId: string; establishmentId: string; rating: number; createdAt: string;
  }) {
    const title = 'Nova avaliação recebida';
    const body = `Você recebeu uma nova avaliação com nota ${data.rating}/5. Confira no painel!`;
    this.logger.log(`[NOTIF] ${title} — estabelecimento: ${data.establishmentId}`);
    await this.save(data.establishmentId, title, body, 'REVIEW_CREATED');
  }

  async sendOrderConfirmation(data: {
    orderId: string; userId: string; total: number; itemCount: number; createdAt: string;
  }) {
    const title = 'Pedido confirmado!';
    const body = `Seu pedido foi confirmado. Total: R$ ${data.total.toFixed(2)} (${data.itemCount} ${data.itemCount === 1 ? 'item' : 'itens'}).`;
    this.logger.log(`[NOTIF] ${title} — pedido: ${data.orderId}`);
    await this.save(data.userId, title, body, 'ORDER_CREATED');
  }

  async sendWelcomeNotification(data: {
    userId: string; name: string; email: string; role: string; registeredAt: string;
  }) {
    const title = 'Bem-vindo ao MyPet!';
    const body = `Olá ${data.name}, seja bem-vindo ao MyPet! Comece agendando serviços para o seu pet.`;
    this.logger.log(`[NOTIF] ${title} — usuário: ${data.name}`);
    await this.save(data.userId, title, body, 'USER_REGISTERED');
  }
}
