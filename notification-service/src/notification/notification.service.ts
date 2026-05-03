import { Injectable, Logger } from '@nestjs/common';

@Injectable()
export class NotificationService {
  private readonly logger = new Logger(NotificationService.name);

  async sendBookingConfirmation(data: {
    bookingId: string; userId: string;
    establishmentId: string; scheduledAt: string;
  }) {
    // TODO em produção: enviar e-mail ou push notification
    this.logger.log(
      `[NOTIFICAÇÃO] Agendamento criado!\n` +
      `  usuário: ${data.userId}\n` +
      `  booking: ${data.bookingId}\n` +
      `  horário: ${data.scheduledAt}\n` +
      `  mensagem: "Seu agendamento foi recebido e está pendente de confirmação."`,
    );
  }

  async sendStatusUpdate(data: {
    bookingId: string; status: 'CONFIRMED' | 'CANCELED'; updatedAt: string;
  }) {
    const msg = data.status === 'CONFIRMED'
      ? 'Seu agendamento foi CONFIRMADO!'
      : 'Seu agendamento foi CANCELADO.';
    this.logger.log(`[NOTIFICAÇÃO] ${msg} — booking: ${data.bookingId}`);
  }

  async sendCompletionNotification(data: { bookingId: string; completedAt: string }) {
    this.logger.log(
      `[NOTIFICAÇÃO] Atendimento finalizado! — booking: ${data.bookingId}\n` +
      `  mensagem: "Seu pet foi atendido! Que tal deixar uma avaliação?"`,
    );
  }

  async sendReviewNotification(data: {
    reviewId: string; userId: string; establishmentId: string; rating: number; createdAt: string;
  }) {
    this.logger.log(
      `[NOTIFICAÇÃO] Nova avaliação recebida!\n` +
      `  estabelecimento: ${data.establishmentId}\n` +
      `  nota: ${data.rating}/5\n` +
      `  mensagem: "Você recebeu uma nova avaliação. Confira no painel!"`,
    );
  }

  async sendOrderConfirmation(data: {
    orderId: string; userId: string; total: number; itemCount: number; createdAt: string;
  }) {
    this.logger.log(
      `[NOTIFICAÇÃO] Pedido realizado!\n` +
      `  usuário: ${data.userId}\n` +
      `  pedido: ${data.orderId}\n` +
      `  total: R$ ${data.total.toFixed(2)} (${data.itemCount} ${data.itemCount === 1 ? 'item' : 'itens'})\n` +
      `  mensagem: "Seu pedido foi confirmado e está sendo processado!"`,
    );
  }

  async sendWelcomeNotification(data: {
    userId: string; name: string; email: string; role: string; registeredAt: string;
  }) {
    this.logger.log(
      `[NOTIFICAÇÃO] Bem-vindo ao MyPet!\n` +
      `  usuário: ${data.name} (${data.email})\n` +
      `  perfil: ${data.role}\n` +
      `  mensagem: "Olá ${data.name}, seja bem-vindo ao MyPet! 🐾"`,
    );
  }
}