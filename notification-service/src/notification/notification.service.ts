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
}