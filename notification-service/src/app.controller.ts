import { Controller, Get, Param, Patch } from '@nestjs/common';
import { AppService } from './app.service';
import { NotificationService } from './notification/notification.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly notificationService: NotificationService,
  ) {}

  @Get('notifications/user/:userId')
  getByUser(@Param('userId') userId: string) {
    return this.appService.getByUser(userId);
  }

  @Patch('notifications/:id/read')
  markRead(@Param('id') id: string) {
    return this.notificationService.markRead(id);
  }
}
