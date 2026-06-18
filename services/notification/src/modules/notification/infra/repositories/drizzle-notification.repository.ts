import { Injectable } from "@nestjs/common";
import { Notification } from "@notification/domain/models/notification.entity";
import type { NotificationRepository } from "@notification/domain/repositories/notification-repository.interface";
import {
  type NotificationRecord,
  notificationsSchema,
} from "@notification/infra/database/schemas/notification.schema";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { desc, eq } from "drizzle-orm";

@Injectable()
export class DrizzleNotificationRepository implements NotificationRepository {
  constructor(private readonly drizzle: DrizzleService) {}

  private toEntity(row: NotificationRecord): Notification {
    return Notification.restore({
      id: row.id,
      userId: row.userId,
      title: row.title,
      body: row.body,
      type: row.type,
      read: row.read,
      createdAt: row.createdAt,
    });
  }

  async create(notification: Notification): Promise<void> {
    await this.drizzle.db.insert(notificationsSchema).values({
      id: notification.id,
      userId: notification.userId,
      title: notification.title,
      body: notification.body,
      type: notification.type,
      read: notification.read,
      createdAt: notification.createdAt,
    });
  }

  async update(notification: Notification): Promise<void> {
    await this.drizzle.db
      .update(notificationsSchema)
      .set({ read: notification.read })
      .where(eq(notificationsSchema.id, notification.id));
  }

  async findById(id: string): Promise<Notification | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(notificationsSchema)
      .where(eq(notificationsSchema.id, id));
    return row ? this.toEntity(row) : null;
  }

  async findByUserId(userId: string): Promise<Notification[]> {
    const rows = await this.drizzle.db
      .select()
      .from(notificationsSchema)
      .where(eq(notificationsSchema.userId, userId))
      .orderBy(desc(notificationsSchema.createdAt));
    return rows.map((r) => this.toEntity(r));
  }

  async countUnread(userId: string): Promise<number> {
    const rows = await this.drizzle.db
      .select()
      .from(notificationsSchema)
      .where(eq(notificationsSchema.userId, userId));
    return rows.filter((r) => !r.read).length;
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.drizzle.db
      .update(notificationsSchema)
      .set({ read: true })
      .where(eq(notificationsSchema.userId, userId));
  }
}
