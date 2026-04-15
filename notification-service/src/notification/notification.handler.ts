import { Controller } from '@nestjs/common';
import { EventPattern, Payload, Ctx, RmqContext } from '@nestjs/microservices';
import { NotificationService } from './notification.service';
import { EVENTS } from '../events/events.constants';

@Controller()
export class NotificationHandler {
  constructor(private readonly notificationService: NotificationService) {}

  @EventPattern(EVENTS.BOOKING_CREATED)
  async handleBookingCreated(
    @Payload() data: { bookingId: string; userId: string; establishmentOwnerId: string; establishmentId: string; scheduledAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.establishmentOwnerId,
      type: 'BOOKING_CREATED',
      title: 'Novo agendamento recebido',
      message: `Você recebeu um novo agendamento para ${data.scheduledAt}.`,
    });
    context.getChannelRef().ack(context.getMessage());
  }

  @EventPattern(EVENTS.BOOKING_CONFIRMED)
  async handleBookingConfirmed(
    @Payload() data: { bookingId: string; userId: string; scheduledAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.userId,
      type: 'BOOKING_CONFIRMED',
      title: 'Agendamento confirmado!',
      message: `Seu agendamento para ${data.scheduledAt} foi confirmado pelo estabelecimento.`,
    });
    context.getChannelRef().ack(context.getMessage());
  }

  @EventPattern(EVENTS.BOOKING_CANCELLED)
  async handleBookingCancelled(
    @Payload() data: { bookingId: string; userId: string; establishmentOwnerId?: string; reason?: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.userId,
      type: 'BOOKING_CANCELLED',
      title: 'Agendamento cancelado',
      message: data.reason ? `Agendamento cancelado. Motivo: ${data.reason}` : 'Seu agendamento foi cancelado.',
    });
    if (data.establishmentOwnerId) {
      await this.notificationService.create({
        userId: data.establishmentOwnerId,
        type: 'BOOKING_CANCELLED',
        title: 'Agendamento cancelado',
        message: 'Um agendamento foi cancelado pelo cliente.',
      });
    }
    context.getChannelRef().ack(context.getMessage());
  }

  @EventPattern(EVENTS.BOOKING_COMPLETED)
  async handleBookingCompleted(
    @Payload() data: { bookingId: string; userId: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.userId,
      type: 'BOOKING_COMPLETED',
      title: 'Atendimento finalizado!',
      message: 'Seu pet foi atendido! Que tal deixar uma avaliação?',
    });
    context.getChannelRef().ack(context.getMessage());
  }

  @EventPattern(EVENTS.REVIEW_CREATED)
  async handleReviewCreated(
    @Payload() data: { reviewId: string; establishmentOwnerId: string; rating: number },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.establishmentOwnerId,
      type: 'REVIEW_CREATED',
      title: 'Nova avaliação recebida',
      message: `Você recebeu uma nova avaliação com nota ${data.rating}.`,
    });
    context.getChannelRef().ack(context.getMessage());
  }

  @EventPattern(EVENTS.COMPLAINT_OPENED)
  async handleComplaintOpened(
    @Payload() data: { complaintId: string; adminId: string; subject: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.adminId,
      type: 'COMPLAINT_OPENED',
      title: 'Nova reclamação aberta',
      message: `Nova reclamação: "${data.subject}"`,
    });
    context.getChannelRef().ack(context.getMessage());
  }

  @EventPattern(EVENTS.COMPLAINT_RESOLVED)
  async handleComplaintResolved(
    @Payload() data: { complaintId: string; userId: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.create({
      userId: data.userId,
      type: 'COMPLAINT_RESOLVED',
      title: 'Sua reclamação foi resolvida',
      message: 'Sua reclamação foi analisada e resolvida pelo administrador.',
    });
    context.getChannelRef().ack(context.getMessage());
  }
}
