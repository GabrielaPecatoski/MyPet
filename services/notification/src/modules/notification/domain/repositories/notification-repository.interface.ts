import type { Notification } from "@notification/domain/models/notification.entity";

export const NOTIFICATION_REPOSITORY = Symbol("NOTIFICATION_REPOSITORY");

export interface NotificationRepository {
  create(notification: Notification): Promise<Notification>;
  update(notification: Notification): Promise<void>;
  findById(id: string): Promise<Notification | null>;
  findByUserId(userId: string): Promise<Notification[]>;
  countUnread(userId: string): Promise<number>;
  markAllAsRead(userId: string): Promise<{ ok: boolean }>;
}
