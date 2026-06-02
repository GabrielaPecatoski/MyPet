import { Module } from "@nestjs/common";
import { BookingService } from "@booking/bookings/application/services/booking.service";
import { AvailabilityService } from "@booking/availability/application/services/availability.service";
import { BOOKING_REPOSITORY } from "@booking/bookings/domain/repositories/booking-repository.interface";
import { SCHEDULE_REPOSITORY, BLOCKED_SLOT_REPOSITORY } from "@booking/availability/domain/repositories/availability-repository.interface";
import { DrizzleBookingRepository } from "@booking/bookings/infra/repositories/drizzle-booking.repository";
import { DrizzleScheduleRepository, DrizzleBlockedSlotRepository } from "@booking/availability/infra/repositories/drizzle-availability.repository";
import { BookingsController, AvailabilityController } from "@booking/bookings/infra/controllers/bookings.controller";

@Module({
  controllers: [BookingsController, AvailabilityController],
  providers: [
    BookingService,
    AvailabilityService,
    DrizzleBookingRepository,
    DrizzleScheduleRepository,
    DrizzleBlockedSlotRepository,
    { provide: BOOKING_REPOSITORY, useExisting: DrizzleBookingRepository },
    { provide: SCHEDULE_REPOSITORY, useExisting: DrizzleScheduleRepository },
    { provide: BLOCKED_SLOT_REPOSITORY, useExisting: DrizzleBlockedSlotRepository },
  ],
})
export class BookingModule {}
