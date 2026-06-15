import { Inject, Injectable, NotFoundException } from "@nestjs/common";
import { Notification } from "@notification/domain/models/notification.entity";
import {
  NOTIFICATION_REPOSITORY,
  type NotificationRepository,
} from "@notification/domain/repositories/notification-repository.interface";
import { DeviceTokenRepository } from "@notification/infra/repositories/device-token.repository";
import { Observable, Subject, interval, merge } from "rxjs";
import { filter, map } from "rxjs/operators";

export interface CreateNotificationDto {
  userId: string;
  title: string;
  body: string;
  type: string;
}

interface SseEvent {
  userId: string;
  data: object;
}

@Injectable()
export class NotificationService {
  private readonly _bus = new Subject<SseEvent>();

  constructor(
    @Inject(NOTIFICATION_REPOSITORY)
    private readonly notificationRepo: NotificationRepository,
    private readonly deviceTokenRepo: DeviceTokenRepository,
  ) {}

  async create(dto: CreateNotificationDto): Promise<Notification> {
    const notification = Notification.restore({
      userId: dto.userId,
      title: dto.title,
      body: dto.body,
      type: dto.type,
    });
    const saved = await this.notificationRepo.create(notification);
    this._bus.next({
      userId: dto.userId,
      data: { type: dto.type, title: dto.title, body: dto.body, id: saved.id },
    });
    return saved;
  }

  getStream(userId: string): Observable<{ data: object }> {
    const events$ = this._bus.pipe(
      filter((e) => e.userId === userId),
      map((e) => ({ data: e.data })),
    );
    const heartbeat$ = interval(25_000).pipe(
      map(() => ({ data: { type: "ping" } })),
    );
    return merge(events$, heartbeat$);
  }

  async listByUser(userId: string): Promise<Notification[]> {
    return this.notificationRepo.findByUserId(userId);
  }

  async countUnread(userId: string): Promise<{ count: number }> {
    const count = await this.notificationRepo.countUnread(userId);
    return { count };
  }

  async markAsRead(id: string): Promise<Notification> {
    const notification = await this.notificationRepo.findById(id);
    if (!notification)
      throw new NotFoundException("Notificação não encontrada");
    notification.markAsRead();
    await this.notificationRepo.update(notification);
    return notification;
  }

  async markAllAsRead(userId: string): Promise<{ ok: boolean }> {
    return this.notificationRepo.markAllAsRead(userId);
  }

  async saveDeviceToken(
    userId: string,
    token: string,
    platform: string,
  ): Promise<void> {
    await this.deviceTokenRepo.save(userId, token, platform);
  }

  async removeDeviceToken(userId: string): Promise<void> {
    await this.deviceTokenRepo.deleteByUserId(userId);
  }
}
