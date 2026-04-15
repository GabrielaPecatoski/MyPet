import {
  Controller, Get, Post, Patch, Delete,
  Param, Body, HttpCode, Headers,
} from '@nestjs/common';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@Controller('bookings')
export class BookingController {
  constructor(private readonly bookingService: BookingService) {}

  @Get()
  findMine(@Headers('x-user-id') userId: string) {
    return this.bookingService.findByUser(userId);
  }

  @Get('user/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.bookingService.findByUser(userId);
  }

  @Get('establishment/:id')
  findByEstablishment(@Param('id') id: string) {
    return this.bookingService.findByEstablishment(id);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.bookingService.findById(id);
  }

  @Post()
  create(@Body() dto: CreateBookingDto) {
    return this.bookingService.create(dto);
  }

  @Patch(':id/confirm')
  confirm(@Param('id') id: string) {
    return this.bookingService.confirm(id);
  }

  @Patch(':id/cancel')
  cancel(@Param('id') id: string, @Body() body: { reason?: string }) {
    return this.bookingService.cancel(id, body?.reason);
  }

  @Patch(':id/complete')
  complete(@Param('id') id: string) {
    return this.bookingService.complete(id);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.bookingService.remove(id);
  }
}
