// @ts-ignore
import { Module } from '@nestjs/common';
// @ts-ignore
import { BookingsService } from './bookings.service';
// @ts-ignore
import { BookingsController } from './bookings.controller';

@Module({
  controllers: [BookingsController],
  providers: [BookingsService],
  exports: [BookingsService],
})
export class BookingsModule {}
