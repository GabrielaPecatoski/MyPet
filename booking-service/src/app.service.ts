import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import * as http from 'http';
import * as fs from 'fs';
import * as path from 'path';

export interface Booking {
  id: string;
  userId: string;
  userName: string;
  petId: string;
  petName: string;
  serviceName: string;
  establishmentId: string;
  establishmentName: string;
  scheduledAt: string;
  price: number;
  status: 'PENDENTE' | 'CONFIRMADO' | 'RECUSADO' | 'CANCELADO' | 'CONCLUIDO';
  createdAt: string;
}

export interface WorkingDay {
  dayOfWeek: number; // 0=Sunday … 6=Saturday
  startTime: string; // "08:00"
  endTime: string;   // "18:00"
  isOpen: boolean;
}

export interface WorkingSchedule {
  establishmentId: string;
  slotDurationMinutes: number; // default 60
  days: WorkingDay[];
}

export interface BlockedSlot {
  id: string;
  establishmentId: string;
  date: string;   // "YYYY-MM-DD"
  time: string;   // "HH:MM"
  reason: string; // "Bloqueado" | "Agendamento"
  isAutomatic: boolean;
}

export interface TimeSlot {
  time: string;
  available: boolean;
  reason?: string;
  blockId?: string;
  bookingId?: string;
}

const NOTIF_URL =
  process.env.NOTIFICATION_SERVICE_URL ?? 'http://localhost:3006';

const DATA_DIR = path.join(process.cwd(), 'data');
const SCHEDULES_FILE = path.join(DATA_DIR, 'schedules.json');
const BLOCKED_FILE   = path.join(DATA_DIR, 'blocked_slots.json');

function ensureDataDir() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
}

function loadJson<T>(file: string, fallback: T): T {
  try {
    if (fs.existsSync(file)) return JSON.parse(fs.readFileSync(file, 'utf-8')) as T;
  } catch {}
  return fallback;
}

function saveJson(file: string, data: unknown) {
  ensureDataDir();
  fs.writeFileSync(file, JSON.stringify(data, null, 2), 'utf-8');
}

function postNotification(body: object): void {
  const data = JSON.stringify(body);
  const url = new URL('/notifications', NOTIF_URL);
  const req = http.request({
    hostname: url.hostname,
    port: Number(url.port) || 3006,
    path: '/notifications',
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Content-Length': Buffer.byteLength(data),
    },
  });
  req.on('error', () => {});
  req.write(data);
  req.end();
}

@Injectable()
export class AppService {
  private bookings: Booking[] = [];
  private schedules: Map<string, WorkingSchedule>;
  private blockedSlots: BlockedSlot[];

  constructor() {
    ensureDataDir();
    const savedSchedules = loadJson<Record<string, WorkingSchedule>>(SCHEDULES_FILE, {});
    this.schedules = new Map(Object.entries(savedSchedules));
    this.blockedSlots = loadJson<BlockedSlot[]>(BLOCKED_FILE, []);
  }

  private persistSchedules() {
    saveJson(SCHEDULES_FILE, Object.fromEntries(this.schedules));
  }

  private persistBlocked() {
    saveJson(BLOCKED_FILE, this.blockedSlots);
  }

  private defaultSchedule(establishmentId: string): WorkingSchedule {
    return {
      establishmentId,
      slotDurationMinutes: 60,
      days: [
        { dayOfWeek: 0, startTime: '08:00', endTime: '12:00', isOpen: false }, // Dom
        { dayOfWeek: 1, startTime: '08:00', endTime: '18:00', isOpen: true },  // Seg
        { dayOfWeek: 2, startTime: '08:00', endTime: '18:00', isOpen: true },  // Ter
        { dayOfWeek: 3, startTime: '08:00', endTime: '18:00', isOpen: true },  // Qua
        { dayOfWeek: 4, startTime: '08:00', endTime: '18:00', isOpen: true },  // Qui
        { dayOfWeek: 5, startTime: '08:00', endTime: '18:00', isOpen: true },  // Sex
        { dayOfWeek: 6, startTime: '08:00', endTime: '14:00', isOpen: true },  // Sáb
      ],
    };
  }

  private generateSlots(startTime: string, endTime: string, durationMinutes: number): string[] {
    const [sh, sm] = startTime.split(':').map(Number);
    const [eh, em] = endTime.split(':').map(Number);
    const startMins = sh * 60 + sm;
    const endMins = eh * 60 + em;
    const slots: string[] = [];
    for (let m = startMins; m + durationMinutes <= endMins; m += durationMinutes) {
      slots.push(`${Math.floor(m / 60).toString().padStart(2, '0')}:${(m % 60).toString().padStart(2, '0')}`);
    }
    return slots;
  }

  findByUser(userId: string): Booking[] {
    return this.bookings
      .filter((b) => b.userId === userId)
      .sort((a, b) => b.scheduledAt.localeCompare(a.scheduledAt));
  }

  findByEstablishment(establishmentId: string): Booking[] {
    return this.bookings
      .filter((b) => b.establishmentId === establishmentId)
      .sort((a, b) => a.scheduledAt.localeCompare(b.scheduledAt));
  }

  findById(id: string): Booking {
    const b = this.bookings.find((b) => b.id === id);
    if (!b) throw new NotFoundException('Agendamento não encontrado');
    return b;
  }

  createBooking(data: {
    userId: string;
    userName?: string;
    petId: string;
    petName: string;
    serviceName: string;
    establishmentId: string;
    establishmentName: string;
    scheduledAt: string;
    price?: number;
  }): Booking {
    const booking: Booking = {
      id: crypto.randomUUID(),
      userId: data.userId,
      userName: data.userName ?? '',
      petId: data.petId,
      petName: data.petName,
      serviceName: data.serviceName,
      establishmentId: data.establishmentId,
      establishmentName: data.establishmentName,
      scheduledAt: data.scheduledAt,
      price: data.price ?? 0,
      status: 'PENDENTE',
      createdAt: new Date().toISOString(),
    };
    this.bookings.push(booking);

    postNotification({
      userId: booking.establishmentId,
      title: 'Novo Agendamento',
      body: `${booking.petName} — ${booking.serviceName} em ${new Date(booking.scheduledAt).toLocaleDateString('pt-BR')}`,
      type: 'NEW_BOOKING',
    });

    return booking;
  }

  updateStatus(id: string, status: 'CONFIRMADO' | 'RECUSADO'): Booking {
    const idx = this.bookings.findIndex((b) => b.id === id);
    if (idx === -1) throw new NotFoundException('Agendamento não encontrado');

    const booking = this.bookings[idx];
    if (booking.status !== 'PENDENTE') {
      throw new BadRequestException(
        'Apenas agendamentos pendentes podem ser confirmados ou recusados',
      );
    }

    this.bookings[idx] = { ...booking, status };

    postNotification({
      userId: booking.userId,
      title:
        status === 'CONFIRMADO'
          ? 'Agendamento Confirmado!'
          : 'Agendamento Recusado',
      body:
        status === 'CONFIRMADO'
          ? `Seu agendamento de ${booking.serviceName} foi confirmado para ${new Date(booking.scheduledAt).toLocaleDateString('pt-BR')}.`
          : `Seu agendamento de ${booking.serviceName} foi recusado pelo estabelecimento.`,
      type: status === 'CONFIRMADO' ? 'BOOKING_CONFIRMED' : 'BOOKING_REJECTED',
    });

    return this.bookings[idx];
  }

  cancelBooking(id: string, userId: string): Booking {
    const idx = this.bookings.findIndex((b) => b.id === id);
    if (idx === -1) throw new NotFoundException('Agendamento não encontrado');
    const booking = this.bookings[idx];

    if (booking.userId !== userId) {
      throw new BadRequestException(
        'Sem permissão para cancelar este agendamento',
      );
    }
    if (booking.status === 'CONCLUIDO') {
      throw new BadRequestException(
        'Agendamento já concluído não pode ser cancelado',
      );
    }
    if (booking.status === 'CANCELADO') {
      throw new BadRequestException('Agendamento já foi cancelado');
    }
    if (booking.status === 'CONFIRMADO') {
      const now = new Date();
      const scheduled = new Date(booking.scheduledAt);
      const isToday =
        scheduled.getFullYear() === now.getFullYear() &&
        scheduled.getMonth() === now.getMonth() &&
        scheduled.getDate() === now.getDate();
      if (!isToday) {
        throw new BadRequestException(
          'Agendamento confirmado só pode ser cancelado no mesmo dia',
        );
      }
    }

    this.bookings[idx] = { ...booking, status: 'CANCELADO' };

    postNotification({
      userId: booking.establishmentId,
      title: 'Agendamento Cancelado',
      body: `O agendamento de ${booking.petName} — ${booking.serviceName} foi cancelado pelo cliente.`,
      type: 'BOOKING_CANCELLED',
    });

    return this.bookings[idx];
  }

  getSchedule(establishmentId: string): WorkingSchedule {
    return this.schedules.get(establishmentId) ?? this.defaultSchedule(establishmentId);
  }

  setSchedule(data: { establishmentId: string; slotDurationMinutes?: number; days: WorkingDay[] }): WorkingSchedule {
    const schedule: WorkingSchedule = {
      establishmentId: data.establishmentId,
      slotDurationMinutes: data.slotDurationMinutes ?? 60,
      days: data.days,
    };
    this.schedules.set(data.establishmentId, schedule);
    this.persistSchedules();
    return schedule;
  }

  getAvailability(establishmentId: string, date: string): { date: string; slots: TimeSlot[] } {
    const d = new Date(date + 'T12:00:00Z');
    const dow = d.getUTCDay(); // 0=Sunday
    const schedule = this.getSchedule(establishmentId);
    const day = schedule.days.find(d => d.dayOfWeek === dow);

    if (!day || !day.isOpen) {
      return { date, slots: [] };
    }

    const rawSlots = this.generateSlots(day.startTime, day.endTime, schedule.slotDurationMinutes);

    const slots: TimeSlot[] = rawSlots.map(time => {
      // Check manual/auto blocked slots
      const block = this.blockedSlots.find(
        b => b.establishmentId === establishmentId && b.date === date && b.time === time,
      );
      if (block) {
        return { time, available: false, reason: block.reason, blockId: block.id };
      }

      // Check existing bookings at this slot
      const booking = this.bookings.find(b => {
        if (b.establishmentId !== establishmentId) return false;
        const bDate = new Date(b.scheduledAt);
        const bDateStr = `${bDate.getUTCFullYear()}-${String(bDate.getUTCMonth() + 1).padStart(2, '0')}-${String(bDate.getUTCDate()).padStart(2, '0')}`;
        const bTime = `${String(bDate.getUTCHours()).padStart(2, '0')}:${String(bDate.getUTCMinutes()).padStart(2, '0')}`;
        return bDateStr === date && bTime === time && b.status !== 'CANCELADO' && b.status !== 'RECUSADO';
      });
      if (booking) {
        return { time, available: false, reason: 'Agendamento', bookingId: booking.id };
      }

      return { time, available: true };
    });

    return { date, slots };
  }

  blockSlot(data: { establishmentId: string; date: string; time: string; reason?: string }): BlockedSlot {
    this.blockedSlots = this.blockedSlots.filter(
      b => !(b.establishmentId === data.establishmentId && b.date === data.date && b.time === data.time),
    );
    const slot: BlockedSlot = {
      id: crypto.randomUUID(),
      establishmentId: data.establishmentId,
      date: data.date,
      time: data.time,
      reason: data.reason ?? 'Bloqueado',
      isAutomatic: false,
    };
    this.blockedSlots.push(slot);
    this.persistBlocked();
    return slot;
  }

  unblockSlot(id: string): void {
    const idx = this.blockedSlots.findIndex(b => b.id === id && !b.isAutomatic);
    if (idx !== -1) {
      this.blockedSlots.splice(idx, 1);
      this.persistBlocked();
    }
  }

  getBlockedSlots(establishmentId: string, date?: string): BlockedSlot[] {
    return this.blockedSlots.filter(
      b => b.establishmentId === establishmentId && (!date || b.date === date),
    );
  }

  completeBooking(id: string): Booking {
    const idx = this.bookings.findIndex((b) => b.id === id);
    if (idx === -1) throw new NotFoundException('Agendamento não encontrado');
    if (this.bookings[idx].status !== 'CONFIRMADO') {
      throw new BadRequestException(
        'Apenas agendamentos confirmados podem ser concluídos',
      );
    }

    this.bookings[idx] = { ...this.bookings[idx], status: 'CONCLUIDO' };
    const booking = this.bookings[idx];

    postNotification({
      userId: booking.userId,
      title: 'Atendimento Concluído!',
      body: 'Seu pet foi atendido! Que tal deixar uma avaliação?',
      type: 'BOOKING_COMPLETED',
    });
    return booking;
  }
}
