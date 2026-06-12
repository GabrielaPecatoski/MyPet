import { AvailabilityService } from "@booking/availability/application/services/availability.service";
import {
  BLOCKED_SLOT_REPOSITORY,
  SCHEDULE_REPOSITORY,
} from "@booking/availability/domain/repositories/availability-repository.interface";
import {
  DrizzleBlockedSlotRepository,
  DrizzleScheduleRepository,
} from "@booking/availability/infra/repositories/drizzle-availability.repository";
import { BookingService } from "@booking/bookings/application/services/booking.service";
import { ExpiredBookingScheduler } from "@booking/bookings/application/services/expired-booking.scheduler";
import { BOOKING_REPOSITORY } from "@booking/bookings/domain/repositories/booking-repository.interface";
import {
  AvailabilityController,
  BookingsController,
} from "@booking/bookings/infra/controllers/bookings.controller";
import { DrizzleBookingRepository } from "@booking/bookings/infra/repositories/drizzle-booking.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [BookingsController, AvailabilityController],
  providers: [
    BookingService,
    ExpiredBookingScheduler,
    AvailabilityService,
    DrizzleBookingRepository,
    DrizzleScheduleRepository,
    DrizzleBlockedSlotRepository,
    { provide: BOOKING_REPOSITORY, useExisting: DrizzleBookingRepository },
    { provide: SCHEDULE_REPOSITORY, useExisting: DrizzleScheduleRepository },
    {
      provide: BLOCKED_SLOT_REPOSITORY,
      useExisting: DrizzleBlockedSlotRepository,
    },
  ],
})
export class BookingModule {}
