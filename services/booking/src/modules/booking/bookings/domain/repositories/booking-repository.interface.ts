import type { Booking } from "@booking/bookings/domain/models/booking.entity";

export const BOOKING_REPOSITORY = Symbol("BOOKING_REPOSITORY");

export interface BookingRepository {
  create(booking: Booking): Promise<void>;
  update(booking: Booking): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Booking | null>;
  findByUserId(userId: string): Promise<Booking[]>;
  findByEstablishmentId(establishmentId: string): Promise<Booking[]>;
  findUpcoming(from: Date, to: Date): Promise<Booking[]>;
}
