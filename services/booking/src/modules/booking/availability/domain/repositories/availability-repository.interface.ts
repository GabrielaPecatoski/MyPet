import type { BlockedSlot } from "@booking/availability/domain/models/blocked-slot.entity";
import type { Schedule } from "@booking/availability/domain/models/schedule.entity";

export const SCHEDULE_REPOSITORY = Symbol("SCHEDULE_REPOSITORY");
export const BLOCKED_SLOT_REPOSITORY = Symbol("BLOCKED_SLOT_REPOSITORY");

export interface ScheduleRepository {
  upsert(schedule: Schedule): Promise<void>;
  findByEstablishmentId(establishmentId: string): Promise<Schedule[]>;
  findByVetId(vetId: string): Promise<Schedule[]>;
}

export interface BlockedSlotRepository {
  create(slot: BlockedSlot): Promise<void>;
  delete(id: string): Promise<void>;
  findByEstablishmentId(establishmentId: string): Promise<BlockedSlot[]>;
  findByVetId(vetId: string): Promise<BlockedSlot[]>;
}
