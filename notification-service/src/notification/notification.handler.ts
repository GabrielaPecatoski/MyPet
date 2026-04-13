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
    @Payload() data: { bookingId: string; status: 'CONFIRMED' | 'CANCELED'; updatedAt: string },
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
}