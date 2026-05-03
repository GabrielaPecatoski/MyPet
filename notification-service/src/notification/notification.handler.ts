import { Controller, Logger } from '@nestjs/common';
import { EventPattern, Payload, Ctx, RmqContext } from '@nestjs/microservices';
import { NotificationService } from './notification.service';
import { EVENTS } from '../events/events.constants';

@Controller()
export class NotificationHandler {
  private readonly logger = new Logger(NotificationHandler.name);

  constructor(private readonly notificationService: NotificationService) {}

  @EventPattern(EVENTS.BOOKING_CREATED)
  async handleBookingCreated(
    @Payload() data: { bookingId: string; userId: string; establishmentId: string; scheduledAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.sendBookingConfirmation(data);
    const channel = context.getChannelRef();
    channel.ack(context.getMessage());
  }

  @EventPattern(EVENTS.BOOKING_STATUS_UPDATED)
  async handleBookingStatusUpdated(
    @Payload() data: { bookingId: string; status: 'CONFIRMADO' | 'RECUSADO'; updatedAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.sendStatusUpdate(data);
    const channel = context.getChannelRef();
    channel.ack(context.getMessage());
  }

  @EventPattern(EVENTS.BOOKING_COMPLETED)
  async handleBookingCompleted(
    @Payload() data: { bookingId: string; completedAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.sendCompletionNotification(data);
    const channel = context.getChannelRef();
    channel.ack(context.getMessage());
  }

  @EventPattern(EVENTS.REVIEW_CREATED)
  async handleReviewCreated(
    @Payload() data: { reviewId: string; userId: string; establishmentId: string; rating: number; createdAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.sendReviewNotification(data);
    const channel = context.getChannelRef();
    channel.ack(context.getMessage());
  }

  @EventPattern(EVENTS.ORDER_CREATED)
  async handleOrderCreated(
    @Payload() data: { orderId: string; userId: string; total: number; itemCount: number; createdAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.sendOrderConfirmation(data);
    const channel = context.getChannelRef();
    channel.ack(context.getMessage());
  }

  @EventPattern(EVENTS.USER_REGISTERED)
  async handleUserRegistered(
    @Payload() data: { userId: string; name: string; email: string; role: string; registeredAt: string },
    @Ctx() context: RmqContext,
  ) {
    await this.notificationService.sendWelcomeNotification(data);
    const channel = context.getChannelRef();
    channel.ack(context.getMessage());
  }
}