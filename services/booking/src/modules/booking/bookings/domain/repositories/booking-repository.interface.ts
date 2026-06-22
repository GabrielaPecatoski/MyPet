import type { Booking } from "@booking/bookings/domain/models/booking.entity";

export const BOOKING_REPOSITORY = Symbol("BOOKING_REPOSITORY");

export interface BookingRepository {
  create(booking: Booking): Promise<Booking>;
  update(booking: Booking): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Booking | null>;
  findByUserId(userId: string): Promise<Booking[]>;
  findByEstablishmentId(establishmentId: string): Promise<Booking[]>;
  findByVetId(vetId: string): Promise<Booking[]>;
  findConfirmedForReminder(
    scheduledFrom: Date,
    scheduledTo: Date,
  ): Promise<Booking[]>;
  findExpiredAwaitingPayment(createdBefore: Date): Promise<Booking[]>;
  findAvailableTransport(
    driverEstablishmentId: string | null,
    openToAllFrom: Date,
  ): Promise<Booking[]>;
  acceptTransport(
    bookingId: string,
    driverId: string,
    driverName?: string,
    driverPhotoUrl?: string,
  ): Promise<Booking | null>;
}
