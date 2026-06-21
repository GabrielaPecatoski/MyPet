import {
  Booking,
  type BookingStatus,
  type PaymentStatus,
} from "@booking/bookings/domain/models/booking.entity";
import type { BookingRepository } from "@booking/bookings/domain/repositories/booking-repository.interface";
import { bookingsSchema } from "@booking/bookings/infra/database/schemas/booking.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { and, eq, gte, isNull, lt } from "drizzle-orm";

@Injectable()
export class DrizzleBookingRepository implements BookingRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(b: Booking): Promise<Booking> {
    const [row] = await this.drizzleService.db
      .insert(bookingsSchema)
      .values({
        userId: b.userId,
        userName: b.userName,
        userEmail: b.userEmail ?? null,
        petId: b.petId,
        petName: b.petName,
        petBreed: b.petBreed || null,
        petAge: b.petAge || null,
        serviceName: b.serviceName,
        servicesJson: b.servicesJson ?? null,
        attendancePhotos: b.attendancePhotosJson ?? null,
        establishmentId: b.establishmentId ?? null,
        establishmentName: b.establishmentName,
        establishmentAddress: b.establishmentAddress || null,
        driverId: b.driverId ?? null,
        driverName: b.driverName ?? null,
        driverPhotoUrl: b.driverPhotoUrl ?? null,
        vetId: b.vetId ?? null,
        vetName: b.vetName ?? null,
        scheduledAt: b.scheduledAt,
        price: b.price,
        priceVariable: b.priceVariable,
        status: b.status,
        paymentStatus: b.paymentStatus,
        paymentMethod: b.paymentMethod ?? null,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();
    return this.toEntity(row)!;
  }

  async update(b: Booking): Promise<void> {
    await this.drizzleService.db
      .update(bookingsSchema)
      .set({
        status: b.status,
        paymentStatus: b.paymentStatus,
        paymentMethod: b.paymentMethod ?? null,
        reminderSentAt: b.reminderSentAt ?? null,
        attendancePhotos: b.attendancePhotosJson ?? null,
        updatedAt: new Date(),
      })
      .where(eq(bookingsSchema.id, b.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db
      .delete(bookingsSchema)
      .where(eq(bookingsSchema.id, id));
  }

  async findById(id: string): Promise<Booking | null> {
    const [row] = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(eq(bookingsSchema.id, id))
      .limit(1);
    return this.toEntity(row);
  }

  async findByUserId(userId: string): Promise<Booking[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(eq(bookingsSchema.userId, userId));
    return rows.map((r) => this.toEntity(r)!);
  }

  async findByEstablishmentId(establishmentId: string): Promise<Booking[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(eq(bookingsSchema.establishmentId, establishmentId));
    return rows.map((r) => this.toEntity(r)!);
  }

  async findByVetId(vetId: string): Promise<Booking[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(eq(bookingsSchema.vetId, vetId));
    return rows.map((r) => this.toEntity(r)!);
  }

  async findConfirmedForReminder(
    scheduledFrom: Date,
    scheduledTo: Date,
  ): Promise<Booking[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(
        and(
          eq(bookingsSchema.status, "CONFIRMADO"),
          isNull(bookingsSchema.reminderSentAt),
          gte(bookingsSchema.scheduledAt, scheduledFrom),
          lt(bookingsSchema.scheduledAt, scheduledTo),
        ),
      );
    return rows.map((r) => this.toEntity(r)!);
  }

  async findExpiredAwaitingPayment(createdBefore: Date): Promise<Booking[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(
        and(
          eq(bookingsSchema.status, "AGUARDANDO_PAGAMENTO"),
          lt(bookingsSchema.createdAt, createdBefore),
        ),
      );
    return rows.map((r) => this.toEntity(r)!);
  }

  private toEntity(
    row: typeof bookingsSchema.$inferSelect | undefined,
  ): Booking | null {
    if (!row) return null;
    return Booking.restore({
      ...row,
      status: row.status as BookingStatus,
      paymentStatus: row.paymentStatus as PaymentStatus,
    });
  }
}
