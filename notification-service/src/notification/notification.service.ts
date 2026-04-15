import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Notification } from './entities/notification.entity';

@Injectable()
export class NotificationService {
  constructor(
    @InjectRepository(Notification)
    private readonly notificationRepo: Repository<Notification>,
  ) {}

  findByUser(userId: string): Promise<Notification[]> {
    return this.notificationRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async markAsRead(id: string, userId: string): Promise<Notification | null> {
    const notification = await this.notificationRepo.findOne({ where: { id, userId } });
    if (!notification) return null;
    notification.read = true;
    return this.notificationRepo.save(notification);
  }

  async markAllAsRead(userId: string): Promise<void> {
    await this.notificationRepo.update({ userId, read: false }, { read: true });
  }

  async countUnread(userId: string): Promise<{ unreadCount: number }> {
    const count = await this.notificationRepo.count({ where: { userId, read: false } });
    return { unreadCount: count };
  }

  async remove(id: string, userId: string): Promise<void> {
    await this.notificationRepo.delete({ id, userId });
  }

  create(data: Partial<Notification>): Promise<Notification> {
    const notification = this.notificationRepo.create(data);
    return this.notificationRepo.save(notification);
  }
}
