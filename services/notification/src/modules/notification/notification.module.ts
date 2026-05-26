import { Module } from "@nestjs/common";
import { NotificationService } from "@notification/application/services/notification.service";
import { DrizzleNotificationRepository } from "@notification/infra/repositories/drizzle-notification.repository";
import { NOTIFICATION_REPOSITORY } from "@notification/domain/repositories/notification-repository.interface";
import { NotificationsController } from "@notification/infra/controllers/notification.controller";
import { NotificationHandler } from "@notification/infra/messaging/notification.handler";

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationService,
    DrizzleNotificationRepository,
    { provide: NOTIFICATION_REPOSITORY, useExisting: DrizzleNotificationRepository },
    NotificationHandler,
  ],
})
export class NotificationModule {}
