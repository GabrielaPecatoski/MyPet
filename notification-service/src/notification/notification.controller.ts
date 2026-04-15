import { Controller, Get, Patch, Delete, Param, Headers, HttpCode } from '@nestjs/common';
import { NotificationService } from './notification.service';

@Controller('notifications')
export class NotificationController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get()
  findByUser(@Headers('x-user-id') userId: string) {
    return this.notificationService.findByUser(userId);
  }

  @Get('unread-count')
  unreadCount(@Headers('x-user-id') userId: string) {
    return this.notificationService.countUnread(userId);
  }

  @Patch(':id/read')
  markRead(@Headers('x-user-id') userId: string, @Param('id') id: string) {
    return this.notificationService.markAsRead(id, userId);
  }

  @Patch('read-all')
  markAllRead(@Headers('x-user-id') userId: string) {
    return this.notificationService.markAllAsRead(userId);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Headers('x-user-id') userId: string, @Param('id') id: string) {
    return this.notificationService.remove(id, userId);
  }
}
