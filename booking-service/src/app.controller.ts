import {
  Controller, Get, Post, Patch, Delete,
  Param, Body, HttpCode,
} from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('bookings/user/:userId')
  getByUser(@Param('userId') userId: string) {
    return this.appService.findByUser(userId);
  }

  @Get('bookings/establishment/:establishmentId')
  getByEstablishment(@Param('establishmentId') id: string) {
    return this.appService.findByEstablishment(id);
  }

  @Get('bookings/:id')
  getById(@Param('id') id: string) {
    return this.appService.findById(id);
  }

  @Post('bookings')
  createBooking(@Body() body: any) {
    return this.appService.createBooking(body);
  }

  @Patch('bookings/:id/status')
  updateStatus(@Param('id') id: string, @Body() body: { status: 'CONFIRMADO' | 'RECUSADO' }) {
    return this.appService.updateStatus(id, body.status);
  }

  @Patch('bookings/:id/complete')
  completeBooking(@Param('id') id: string) {
    return this.appService.completeBooking(id);
  }

  @Delete('bookings/:id')
  @HttpCode(204)
  deleteBooking(@Param('id') id: string) {
    this.appService.removeBooking(id);
  }
}
