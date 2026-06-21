import {
  Booking,
  type BookingStatus,
  type PaymentStatus,
} from "@booking/bookings/domain/models/booking.entity";
import type { BookingRepository } from "@booking/bookings/domain/repositories/booking-repository.interface";
import { bookingsSchema } from "@booking/bookings/infra/database/schemas/booking.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { and, eq, gte, isNull, lt, lte, notInArray, or } from "drizzle-orm";

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
        transportStatus: b.transportStatus,
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

  async findAvailableTransport(
    driverEstablishmentId: string | null,
    openToAllFrom: Date,
  ): Promise<Booking[]> {
    // "vinculados primeiro": o motorista vê as corridas do seu estabelecimento
    // sempre; e qualquer corrida cujo atendimento esteja a até 5h (openToAllFrom
    // = agora + 5h) fica aberta a todos.
    const openToAll = lte(bookingsSchema.scheduledAt, openToAllFrom);
    const visibility = driverEstablishmentId
      ? or(
          eq(bookingsSchema.establishmentId, driverEstablishmentId),
          openToAll,
        )
      : openToAll;

    const rows = await this.drizzleService.db
      .select()
      .from(bookingsSchema)
      .where(
        and(
          eq(bookingsSchema.transportStatus, "PENDING"),
          isNull(bookingsSchema.driverId),
          notInArray(bookingsSchema.status, [
            "CANCELADO",
            "RECUSADO",
            "CONCLUIDO",
          ]),
          visibility,
        ),
      );
    return rows.map((r) => this.toEntity(r)!);
  }

  async acceptTransport(
    bookingId: string,
    driverId: string,
    driverName?: string,
    driverPhotoUrl?: string,
  ): Promise<Booking | null> {
    // Atribuição atômica: só atualiza se a corrida ainda estiver PENDING e sem
    // motorista. O segundo motorista a tentar não atualiza nenhuma linha.
    const [row] = await this.drizzleService.db
      .update(bookingsSchema)
      .set({
        driverId,
        driverName: driverName ?? null,
        driverPhotoUrl: driverPhotoUrl ?? null,
        transportStatus: "ACCEPTED",
        updatedAt: new Date(),
      })
      .where(
        and(
          eq(bookingsSchema.id, bookingId),
          isNull(bookingsSchema.driverId),
          eq(bookingsSchema.transportStatus, "PENDING"),
        ),
      )
      .returning();
    return this.toEntity(row);
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
