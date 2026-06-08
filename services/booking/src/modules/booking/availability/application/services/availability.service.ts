import { BlockedSlot } from "@booking/availability/domain/models/blocked-slot.entity";
import { Schedule } from "@booking/availability/domain/models/schedule.entity";
import {
  BLOCKED_SLOT_REPOSITORY,
  type BlockedSlotRepository,
  SCHEDULE_REPOSITORY,
  type ScheduleRepository,
} from "@booking/availability/domain/repositories/availability-repository.interface";
import {
  BOOKING_REPOSITORY,
  type BookingRepository,
} from "@booking/bookings/domain/repositories/booking-repository.interface";
import { Inject, Injectable } from "@nestjs/common";

const ALL_DAYS = [0, 1, 2, 3, 4, 5, 6];
const DEFAULT_TIMES: Record<number, { open: string; close: string }> = {
  0: { open: "08:00", close: "12:00" },
  1: { open: "08:00", close: "18:00" },
  2: { open: "08:00", close: "18:00" },
  3: { open: "08:00", close: "18:00" },
  4: { open: "08:00", close: "18:00" },
  5: { open: "08:00", close: "18:00" },
  6: { open: "08:00", close: "14:00" },
};

@Injectable()
export class AvailabilityService {
  constructor(
    @Inject(SCHEDULE_REPOSITORY)
    private readonly scheduleRepo: ScheduleRepository,
    @Inject(BLOCKED_SLOT_REPOSITORY)
    private readonly blockedRepo: BlockedSlotRepository,
    @Inject(BOOKING_REPOSITORY) private readonly bookingRepo: BookingRepository,
  ) {}

  async setFullSchedule(dto: {
    establishmentId: string;
    slotDurationMinutes: number;
    capacity?: number;
    days: {
      dayOfWeek: number;
      startTime: string;
      endTime: string;
      isOpen: boolean;
    }[];
  }): Promise<void> {
    for (const day of dto.days) {
      const schedule = Schedule.restore({
        establishmentId: dto.establishmentId,
        dayOfWeek: day.dayOfWeek,
        openTime: day.startTime,
        closeTime: day.endTime,
        slotDuration: dto.slotDurationMinutes,
        isOpen: day.isOpen,
        capacity: dto.capacity ?? 1,
      })!;
      await this.scheduleRepo.upsert(schedule);
    }
  }

  async getFullSchedule(establishmentId: string) {
    const rows = await this.scheduleRepo.findByEstablishmentId(establishmentId);
    const byDay = new Map(rows.map((r) => [r.dayOfWeek, r]));

    const slotDuration = rows[0]?.slotDuration ?? 60;
    const capacity = rows[0]?.capacity ?? 1;

    const days = ALL_DAYS.map((d) => {
      const row = byDay.get(d);
      const def = DEFAULT_TIMES[d];
      return {
        dayOfWeek: d,
        startTime: row?.openTime ?? def.open,
        endTime: row?.closeTime ?? def.close,
        isOpen: row?.isOpen ?? (d >= 1 && d <= 5),
      };
    });

    return {
      establishmentId,
      slotDurationMinutes: slotDuration,
      capacity,
      days,
    };
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

  async getAvailableSlots(
    establishmentId: string,
    date: string,
  ): Promise<{ slots: SlotInfo[] }> {
    const d = new Date(`${date}T00:00:00`);
    const dayOfWeek = d.getDay();

    const schedules =
      await this.scheduleRepo.findByEstablishmentId(establishmentId);
    const daySchedule = schedules.find((s) => s.dayOfWeek === dayOfWeek);

    let openTime: string;
    let closeTime: string;
    let slotDuration: number;
    let capacity: number;

    if (daySchedule) {
      if (!daySchedule.isOpen) return { slots: [] };
      openTime = daySchedule.openTime;
      closeTime = daySchedule.closeTime;
      slotDuration = daySchedule.slotDuration;
      capacity = daySchedule.capacity;
    } else {
      const isOpenByDefault = dayOfWeek >= 1 && dayOfWeek <= 5;
      if (!isOpenByDefault) return { slots: [] };
      const def = DEFAULT_TIMES[dayOfWeek];
      openTime = def.open;
      closeTime = def.close;
      slotDuration = 60;
      capacity = 1;
    }

    const blocked =
      await this.blockedRepo.findByEstablishmentId(establishmentId);
    const blockedOnDate = blocked.filter((b) => b.date === date);

    const bookings =
      await this.bookingRepo.findByEstablishmentId(establishmentId);
    const bookingsOnDate = bookings.filter((b) => {
      const bd = b.scheduledAt;
      return (
        bd.getFullYear() === d.getFullYear() &&
        bd.getMonth() === d.getMonth() &&
        bd.getDate() === d.getDate() &&
        b.status === "CONFIRMADO"
      );
    });

    const slots: SlotInfo[] = [];
    const [openH, openM] = openTime.split(":").map(Number);
    const [closeH, closeM] = closeTime.split(":").map(Number);
    const openMinutes = openH * 60 + openM;
    const closeMinutes = closeH * 60 + closeM;

    for (let m = openMinutes; m < closeMinutes; m += slotDuration) {
      const h = String(Math.floor(m / 60)).padStart(2, "0");
      const min = String(m % 60).padStart(2, "0");
      const slotTime = `${h}:${min}`;

      const block = blockedOnDate.find(
        (b) => b.startTime <= slotTime && slotTime < b.endTime,
      );
      if (block) {
        slots.push({
          time: slotTime,
          available: false,
          blockId: block.id,
          bookingId: null,
        });
        continue;
      }

      const slotBookings = bookingsOnDate.filter((b) => {
        const bh = String(b.scheduledAt.getHours()).padStart(2, "0");
        const bm = String(b.scheduledAt.getMinutes()).padStart(2, "0");
        return `${bh}:${bm}` === slotTime;
      });

      if (slotBookings.length >= capacity) {
        slots.push({
          time: slotTime,
          available: false,
          blockId: null,
          bookingId: slotBookings[0].id ?? null,
        });
      } else {
        slots.push({
          time: slotTime,
          available: true,
          blockId: null,
          bookingId: null,
        });
      }
    }

    return { slots };
  }
}

export interface SlotInfo {
  time: string;
  available: boolean;
  blockId: string | null | undefined;
  bookingId: string | null | undefined;
}
