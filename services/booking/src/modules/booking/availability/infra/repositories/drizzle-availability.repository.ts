import { BlockedSlot } from "@booking/availability/domain/models/blocked-slot.entity";
import { Schedule } from "@booking/availability/domain/models/schedule.entity";
import type { BlockedSlotRepository, ScheduleRepository } from "@booking/availability/domain/repositories/availability-repository.interface";
import { blockedSlotsSchema, schedulesSchema } from "@booking/availability/infra/database/schemas/availability.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { and, eq, isNull } from "drizzle-orm";

@Injectable()
export class DrizzleScheduleRepository implements ScheduleRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async upsert(schedule: Schedule): Promise<void> {
    let condition;
    if (schedule.establishmentId) {
      condition = and(eq(schedulesSchema.establishmentId, schedule.establishmentId), eq(schedulesSchema.dayOfWeek, schedule.dayOfWeek));
    } else if (schedule.vetId) {
      condition = and(eq(schedulesSchema.vetId, schedule.vetId), eq(schedulesSchema.dayOfWeek, schedule.dayOfWeek));
    }
    if (condition) {
      await this.drizzleService.db.delete(schedulesSchema).where(condition);
    }
    await this.drizzleService.db.insert(schedulesSchema).values({
      establishmentId: schedule.establishmentId ?? null,
      vetId: schedule.vetId ?? null,
      dayOfWeek: schedule.dayOfWeek,
      openTime: schedule.openTime,
      closeTime: schedule.closeTime,
      slotDuration: schedule.slotDuration,
      isOpen: schedule.isOpen,
      capacity: schedule.capacity,
    });
  }

  async findByEstablishmentId(establishmentId: string): Promise<Schedule[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(schedulesSchema)
      .where(and(eq(schedulesSchema.establishmentId, establishmentId), isNull(schedulesSchema.vetId)));
    return rows.map((r) =>
      Schedule.restore({
        ...r,
        isOpen: r.isOpen ?? true,
        capacity: r.capacity ?? 1,
      })!,
    );
  }

  async findByVetId(vetId: string): Promise<Schedule[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(schedulesSchema)
      .where(and(eq(schedulesSchema.vetId, vetId), isNull(schedulesSchema.establishmentId)));
    return rows.map((r) =>
      Schedule.restore({
        ...r,
        isOpen: r.isOpen ?? true,
        capacity: r.capacity ?? 1,
      })!,
    );
  }
}

@Injectable()
export class DrizzleBlockedSlotRepository implements BlockedSlotRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(slot: BlockedSlot): Promise<void> {
    await this.drizzleService.db.insert(blockedSlotsSchema).values({
      establishmentId: slot.establishmentId ?? null,
      vetId: slot.vetId ?? null,
      date: slot.date,
      startTime: slot.startTime,
      endTime: slot.endTime,
      reason: slot.reason,
    });
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(blockedSlotsSchema).where(eq(blockedSlotsSchema.id, id));
  }

  async findByEstablishmentId(establishmentId: string): Promise<BlockedSlot[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(blockedSlotsSchema)
      .where(and(eq(blockedSlotsSchema.establishmentId, establishmentId), isNull(blockedSlotsSchema.vetId)));
    return rows.map((r) => BlockedSlot.restore({ ...r, reason: r.reason ?? undefined })!);
  }

  async findByVetId(vetId: string): Promise<BlockedSlot[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(blockedSlotsSchema)
      .where(and(eq(blockedSlotsSchema.vetId, vetId), isNull(blockedSlotsSchema.establishmentId)));
    return rows.map((r) => BlockedSlot.restore({ ...r, reason: r.reason ?? undefined })!);
  }
}
