import { Booking, type BookingStatus } from "@booking/bookings/domain/models/booking.entity";
import type { BookingRepository } from "@booking/bookings/domain/repositories/booking-repository.interface";
import { bookingsSchema } from "@booking/bookings/infra/database/schemas/booking.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DrizzleBookingRepository implements BookingRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(b: Booking): Promise<void> {
    await this.drizzleService.db.insert(bookingsSchema).values({
      userId: b.userId,
      userName: b.userName,
      petId: b.petId,
      petName: b.petName,
      serviceName: b.serviceName,
      servicesJson: b.servicesJson ?? null,
      establishmentId: b.establishmentId,
      establishmentName: b.establishmentName,
      scheduledAt: b.scheduledAt,
      price: b.price,
      status: b.status,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  async update(b: Booking): Promise<void> {
    await this.drizzleService.db
      .update(bookingsSchema)
      .set({ status: b.status, updatedAt: new Date() })
      .where(eq(bookingsSchema.id, b.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(bookingsSchema).where(eq(bookingsSchema.id, id));
  }

  async findById(id: string): Promise<Booking | null> {
    const [row] = await this.drizzleService.db.select().from(bookingsSchema).where(eq(bookingsSchema.id, id)).limit(1);
    return this.toEntity(row);
  }

  async findByUserId(userId: string): Promise<Booking[]> {
    const rows = await this.drizzleService.db.select().from(bookingsSchema).where(eq(bookingsSchema.userId, userId));
    return rows.map((r) => this.toEntity(r)!);
  }

  async findByEstablishmentId(establishmentId: string): Promise<Booking[]> {
    const rows = await this.drizzleService.db.select().from(bookingsSchema).where(eq(bookingsSchema.establishmentId, establishmentId));
    return rows.map((r) => this.toEntity(r)!);
  }

  private toEntity(row: typeof bookingsSchema.$inferSelect | undefined): Booking | null {
    if (!row) return null;
    return Booking.restore({ ...row, status: row.status as BookingStatus });
  }
}
