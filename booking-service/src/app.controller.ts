import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Headers,
  HttpCode,
  Query,
  UnauthorizedException,
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
  createBooking(
    @Body()
    body: {
      userId: string;
      userName?: string;
      petId: string;
      petName: string;
      serviceName: string;
      establishmentId: string;
      establishmentName: string;
      scheduledAt: string;
      price?: number;
    },
  ) {
    return this.appService.createBooking(body);
  }

  @Patch('bookings/:id/status')
  updateStatus(
    @Param('id') id: string,
    @Body() body: { status: 'CONFIRMADO' | 'RECUSADO' },
  ) {
    return this.appService.updateStatus(id, body.status);
  }

  @Patch('bookings/:id/cancel')
  cancelBooking(@Param('id') id: string, @Headers('x-user-id') userId: string) {
    if (!userId) throw new UnauthorizedException();
    return this.appService.cancelBooking(id, userId);
  }

  @Patch('bookings/:id/complete')
  completeBooking(@Param('id') id: string) {
    return this.appService.completeBooking(id);
  }

  @Delete('bookings/:id')
  @HttpCode(204)
  deleteBooking() {}

  // ── Availability ──────────────────────────────────────────────────

  @Get('availability/schedule/:estabId')
  getSchedule(@Param('estabId') estabId: string) {
    return this.appService.getSchedule(estabId);
  }

  @Get('availability/blocked/:estabId')
  getBlockedSlots(
    @Param('estabId') estabId: string,
    @Query('date') date?: string,
  ) {
    return this.appService.getBlockedSlots(estabId, date);
  }

  @Post('availability/schedule')
  setSchedule(
    @Body() body: { establishmentId: string; slotDurationMinutes?: number; days: any[] },
  ) {
    return this.appService.setSchedule(body);
  }

  @Post('availability/block')
  blockSlot(
    @Body() body: { establishmentId: string; date: string; time: string; reason?: string },
  ) {
    return this.appService.blockSlot(body);
  }

  @Delete('availability/block/:id')
  @HttpCode(204)
  unblockSlot(@Param('id') id: string) {
    this.appService.unblockSlot(id);
  }

  @Get('availability/:estabId')
  getAvailability(
    @Param('estabId') estabId: string,
    @Query('date') date: string,
  ) {
    return this.appService.getAvailability(estabId, date ?? new Date().toISOString().split('T')[0]);
  }
}
