import { BlockedSlot } from "@booking/availability/domain/models/blocked-slot.entity";
import { Schedule } from "@booking/availability/domain/models/schedule.entity";
import {
  BLOCKED_SLOT_REPOSITORY,
  SCHEDULE_REPOSITORY,
  type BlockedSlotRepository,
  type ScheduleRepository,
} from "@booking/availability/domain/repositories/availability-repository.interface";
import { Inject, Injectable } from "@nestjs/common";

@Injectable()
export class AvailabilityService {
  constructor(
    @Inject(SCHEDULE_REPOSITORY) private readonly scheduleRepo: ScheduleRepository,
    @Inject(BLOCKED_SLOT_REPOSITORY) private readonly blockedRepo: BlockedSlotRepository,
  ) {}

  async setSchedule(dto: {
    establishmentId: string;
    dayOfWeek: number;
    openTime: string;
    closeTime: string;
    slotDuration?: number;
  }): Promise<void> {
    const schedule = Schedule.restore({
      establishmentId: dto.establishmentId,
      dayOfWeek: dto.dayOfWeek,
      openTime: dto.openTime,
      closeTime: dto.closeTime,
      slotDuration: dto.slotDuration ?? 30,
    })!;
    await this.scheduleRepo.upsert(schedule);
  }

  async getSchedule(establishmentId: string) {
    return this.scheduleRepo.findByEstablishmentId(establishmentId);
  }

  async blockSlot(dto: {
    establishmentId: string;
    date: string;
    startTime: string;
    endTime: string;
    reason?: string;
  }): Promise<void> {
    const slot = BlockedSlot.restore(dto)!;
    await this.blockedRepo.create(slot);
  }

  async getBlockedSlots(establishmentId: string) {
    return this.blockedRepo.findByEstablishmentId(establishmentId);
  }

  async unblockSlot(id: string): Promise<void> {
    await this.blockedRepo.delete(id);
  }

  async getAvailableSlots(establishmentId: string, date: string): Promise<string[]> {
    const d = new Date(date);
    const dayOfWeek = d.getDay();

    const schedules = await this.scheduleRepo.findByEstablishmentId(establishmentId);
    const daySchedule = schedules.find((s) => s.dayOfWeek === dayOfWeek);
    if (!daySchedule) return [];

    const blocked = await this.blockedRepo.findByEstablishmentId(establishmentId);
    const blockedOnDate = blocked.filter((b) => b.date === date);

    const slots: string[] = [];
    const [openH, openM] = daySchedule.openTime.split(":").map(Number);
    const [closeH, closeM] = daySchedule.closeTime.split(":").map(Number);
    const openMinutes = openH * 60 + openM;
    const closeMinutes = closeH * 60 + closeM;

    for (let m = openMinutes; m < closeMinutes; m += daySchedule.slotDuration) {
      const h = String(Math.floor(m / 60)).padStart(2, "0");
      const min = String(m % 60).padStart(2, "0");
      const slot = `${h}:${min}`;

      const isBlocked = blockedOnDate.some((b) => b.startTime <= slot && slot < b.endTime);
      if (!isBlocked) slots.push(slot);
    }

    return slots;
  }
}
