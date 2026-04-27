import { Body, Controller, Get, Param, Patch, Post } from '@nestjs/common';
import { NotificationService } from './notification.service';

@Controller('notifications')
export class NotificationController {
  constructor(private readonly svc: NotificationService) {}

  @Post()
  create(
    @Body() body: { userId: string; title: string; body: string; type: any },
  ) {
    return this.svc.create(body);
  }

  @Get('user/:userId')
  getByUser(@Param('userId') userId: string) {
    return this.svc.getByUser(userId);
  }

  @Get('user/:userId/unread')
  async countUnread(@Param('userId') userId: string) {
    const count = await this.svc.countUnread(userId);
    return { count };
  }

  @Patch(':id/read')
  markRead(@Param('id') id: string) {
    return this.svc.markRead(id);
  }

  @Patch('user/:userId/read-all')
  async markAllRead(@Param('userId') userId: string) {
    await this.svc.markAllRead(userId);
    return { ok: true };
  }
}
