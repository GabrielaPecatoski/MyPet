import { Module } from "@nestjs/common";
import { NotificationService } from "@notification/application/services/notification.service";
import { NotificationStreamService } from "@notification/application/services/notification-stream.service";
import { NOTIFICATION_REPOSITORY } from "@notification/domain/repositories/notification-repository.interface";
import { NotificationsController } from "@notification/infra/controllers/notification.controller";
import { MailService } from "@notification/infra/mail/mail.service";
import { NotificationHandler } from "@notification/infra/messaging/notification.handler";
import { FcmService } from "@notification/infra/push/fcm.service";
import { DeviceTokenRepository } from "@notification/infra/repositories/device-token.repository";
import { DrizzleNotificationRepository } from "@notification/infra/repositories/drizzle-notification.repository";

@Module({
  controllers: [NotificationsController],
  providers: [
    NotificationService,
    NotificationStreamService,
    DrizzleNotificationRepository,
    {
      provide: NOTIFICATION_REPOSITORY,
      useExisting: DrizzleNotificationRepository,
    },
    DeviceTokenRepository,
    FcmService,
    NotificationHandler,
    MailService,
  ],
})
export class NotificationModule {}
