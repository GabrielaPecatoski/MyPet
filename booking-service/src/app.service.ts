import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as crypto from 'crypto';
import * as http from 'http';
import * as fs from 'fs';
import * as path from 'path';
import { PrismaService } from './prisma.service';

export type BookingStatus = 'PENDENTE' | 'CONFIRMADO' | 'A_CAMINHO' | 'RECUSADO' | 'CANCELADO' | 'CONCLUIDO';

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
  status: BookingStatus;
  pago: boolean;
  createdAt: string;
}

export interface WorkingDay {
  dayOfWeek: number;
  startTime: string;
  endTime: string;
  isOpen: boolean;
}

export interface WorkingSchedule {
  establishmentId: string;
  slotDurationMinutes: number;
  days: WorkingDay[];
}

export interface BlockedSlot {
  id: string;
  establishmentId: string;
  date: string;
  time: string;
  reason: string;
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
const BLOCKED_FILE = path.join(DATA_DIR, 'blocked_slots.json');

const PT_MONTHS = [
  'Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun',
  'Jul', 'Ago', 'Set', 'Out', 'Nov', 'Dez',
];

function ensureDataDir() {
  if (!fs.existsSync(DATA_DIR)) fs.mkdirSync(DATA_DIR, { recursive: true });
}

function loadJson<T>(file: string, fallback: T): T {
  try {
    if (fs.existsSync(file))
      return JSON.parse(fs.readFileSync(file, 'utf-8')) as T;
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
  private schedules: Map<string, WorkingSchedule>;
  private blockedSlots: BlockedSlot[];

  constructor(private readonly prisma: PrismaService) {
    ensureDataDir();
    const savedSchedules = loadJson<Record<string, WorkingSchedule>>(
      SCHEDULES_FILE,
      {},
    );
    this.schedules = new Map(Object.entries(savedSchedules));
    this.blockedSlots = loadJson<BlockedSlot[]>(BLOCKED_FILE, []);
  }

  private persistSchedules() {
    saveJson(SCHEDULES_FILE, Object.fromEntries(this.schedules));
  }

  private persistBlocked() {
    saveJson(BLOCKED_FILE, this.blockedSlots);
  }

  private toBooking(b: any): Booking {
    return {
      id: b.id,
      userId: b.userId,
      userName: b.userName,
      petId: b.petId,
      petName: b.petName,
      serviceName: b.serviceName,
      establishmentId: b.establishmentId,
      establishmentName: b.establishmentName,
      scheduledAt:
        b.scheduledAt instanceof Date
          ? b.scheduledAt.toISOString()
          : b.scheduledAt,
      price: b.price,
      status: b.status as BookingStatus,
      pago: b.pago ?? false,
      createdAt:
        b.createdAt instanceof Date ? b.createdAt.toISOString() : b.createdAt,
    };
  }

  private defaultSchedule(establishmentId: string): WorkingSchedule {
    return {
      establishmentId,
      slotDurationMinutes: 60,
      days: [
        { dayOfWeek: 0, startTime: '08:00', endTime: '12:00', isOpen: false },
        { dayOfWeek: 1, startTime: '08:00', endTime: '18:00', isOpen: true },
        { dayOfWeek: 2, startTime: '08:00', endTime: '18:00', isOpen: true },
        { dayOfWeek: 3, startTime: '08:00', endTime: '18:00', isOpen: true },
        { dayOfWeek: 4, startTime: '08:00', endTime: '18:00', isOpen: true },
        { dayOfWeek: 5, startTime: '08:00', endTime: '18:00', isOpen: true },
        { dayOfWeek: 6, startTime: '08:00', endTime: '14:00', isOpen: true },
      ],
    };
  }

  private generateSlots(
    startTime: string,
    endTime: string,
    durationMinutes: number,
  ): string[] {
    const [sh, sm] = startTime.split(':').map(Number);
    const [eh, em] = endTime.split(':').map(Number);
    const startMins = sh * 60 + sm;
    const endMins = eh * 60 + em;
    const slots: string[] = [];
    for (
      let m = startMins;
      m + durationMinutes <= endMins;
      m += durationMinutes
    ) {
      slots.push(
        `${Math.floor(m / 60)
          .toString()
          .padStart(2, '0')}:${(m % 60).toString().padStart(2, '0')}`,
      );
    }
    return slots;
  }

  async findByUser(userId: string): Promise<Booking[]> {
    const bookings = await this.prisma.booking.findMany({
      where: { userId },
      orderBy: { scheduledAt: 'desc' },
    });
    return bookings.map((b) => this.toBooking(b));
  }

  async findByEstablishment(establishmentId: string): Promise<Booking[]> {
    const bookings = await this.prisma.booking.findMany({
      where: { establishmentId },
      orderBy: { scheduledAt: 'asc' },
    });
    return bookings.map((b) => this.toBooking(b));
  }

  async findById(id: string): Promise<Booking> {
    const b = await this.prisma.booking.findUnique({ where: { id } });
    if (!b) throw new NotFoundException('Agendamento não encontrado');
    return this.toBooking(b);
  }

  async createBooking(data: {
    userId: string;
    userName?: string;
    petId: string;
    petName: string;
    serviceName: string;
    establishmentId: string;
    establishmentName: string;
    scheduledAt: string;
    price?: number;
  }): Promise<Booking> {
    const booking = await this.prisma.booking.create({
      data: {
        userId: data.userId,
        userName: data.userName ?? '',
        petId: data.petId,
        petName: data.petName,
        serviceName: data.serviceName,
        establishmentId: data.establishmentId,
        establishmentName: data.establishmentName,
        scheduledAt: new Date(data.scheduledAt),
        price: data.price ?? 0,
        status: 'PENDENTE',
      },
    });

    postNotification({
      userId: booking.establishmentId,
      title: 'Novo Agendamento',
      body: `${booking.petName} — ${booking.serviceName} em ${new Date(booking.scheduledAt).toLocaleDateString('pt-BR')}`,
      type: 'NEW_BOOKING',
    });

    return this.toBooking(booking);
  }

  async updateStatus(id: string, status: BookingStatus): Promise<Booking> {
    const booking = await this.findById(id);

    const validTransitions: Record<string, BookingStatus[]> = {
      PENDENTE: ['CONFIRMADO', 'RECUSADO'],
      CONFIRMADO: ['A_CAMINHO', 'CONCLUIDO', 'CANCELADO'],
      A_CAMINHO: ['CONCLUIDO', 'CANCELADO'],
    };

    const allowed = validTransitions[booking.status] ?? [];
    if (!allowed.includes(status)) {
      throw new BadRequestException(
        `Não é possível mudar de ${booking.status} para ${status}`,
      );
    }

    const updated = await this.prisma.booking.update({
      where: { id },
      data: { status },
    });

    const notifMap: Record<string, { title: string; body: string; type: string }> = {
      CONFIRMADO: {
        title: 'Agendamento Confirmado!',
        body: `Seu agendamento de ${booking.serviceName} foi confirmado para ${new Date(booking.scheduledAt).toLocaleDateString('pt-BR')}.`,
        type: 'BOOKING_CONFIRMED',
      },
      RECUSADO: {
        title: 'Agendamento Recusado',
        body: `Seu agendamento de ${booking.serviceName} foi recusado pelo estabelecimento.`,
        type: 'BOOKING_REJECTED',
      },
      A_CAMINHO: {
        title: 'Estabelecimento a caminho!',
        body: `O estabelecimento está a caminho para buscar ${booking.petName}.`,
        type: 'ESTAB_ON_THE_WAY',
      },
      CONCLUIDO: {
        title: 'Atendimento Concluído!',
        body: 'Seu pet foi atendido! Que tal deixar uma avaliação?',
        type: 'BOOKING_COMPLETED',
      },
    };

    if (notifMap[status]) {
      postNotification({ userId: booking.userId, ...notifMap[status] });
    }

    return this.toBooking(updated);
  }

  async markAsPaid(id: string): Promise<Booking> {
    const booking = await this.findById(id);
    if (booking.pago) {
      throw new BadRequestException('Agendamento já foi pago');
    }
    if (!['PENDENTE', 'CONFIRMADO', 'A_CAMINHO'].includes(booking.status)) {
      throw new BadRequestException('Agendamento não pode ser pago neste status');
    }

    const scheduledAt = new Date(booking.scheduledAt);
    const oneHourBefore = new Date(scheduledAt.getTime() - 60 * 60 * 1000);
    if (new Date() > oneHourBefore) {
      throw new BadRequestException(
        'Prazo de pagamento encerrado (até 1 hora antes do serviço)',
      );
    }

    const updated = await this.prisma.booking.update({
      where: { id },
      data: { pago: true },
    });

    postNotification({
      userId: booking.establishmentId,
      title: 'Pagamento Recebido',
      body: `Pagamento do serviço ${booking.serviceName} de ${booking.userName} confirmado.`,
      type: 'BOOKING_PAID',
    });

    return this.toBooking(updated);
  }

  async cancelBooking(id: string, userId: string): Promise<Booking> {
    const booking = await this.findById(id);

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

    const updated = await this.prisma.booking.update({
      where: { id },
      data: { status: 'CANCELADO' },
    });

    postNotification({
      userId: booking.establishmentId,
      title: 'Agendamento Cancelado',
      body: `O agendamento de ${booking.petName} — ${booking.serviceName} foi cancelado pelo cliente.`,
      type: 'BOOKING_CANCELLED',
    });

    return this.toBooking(updated);
  }

  async completeBooking(id: string): Promise<Booking> {
    return this.updateStatus(id, 'CONCLUIDO');
  }

  getSchedule(establishmentId: string): WorkingSchedule {
    return (
      this.schedules.get(establishmentId) ??
      this.defaultSchedule(establishmentId)
    );
  }

  setSchedule(data: {
    establishmentId: string;
    slotDurationMinutes?: number;
    days: WorkingDay[];
  }): WorkingSchedule {
    const schedule: WorkingSchedule = {
      establishmentId: data.establishmentId,
      slotDurationMinutes: data.slotDurationMinutes ?? 60,
      days: data.days,
    };
    this.schedules.set(data.establishmentId, schedule);
    this.persistSchedules();
    return schedule;
  }

  async getAvailability(
    establishmentId: string,
    date: string,
  ): Promise<{ date: string; slots: TimeSlot[] }> {
    const d = new Date(date + 'T12:00:00Z');
    const dow = d.getUTCDay();
    const schedule = this.getSchedule(establishmentId);
    const day = schedule.days.find((d) => d.dayOfWeek === dow);

    if (!day || !day.isOpen) {
      return { date, slots: [] };
    }

    const rawSlots = this.generateSlots(
      day.startTime,
      day.endTime,
      schedule.slotDurationMinutes,
    );

    const startOfDay = new Date(date + 'T00:00:00Z');
    const endOfDay = new Date(date + 'T23:59:59Z');
    const dayBookings = await this.prisma.booking.findMany({
      where: {
        establishmentId,
        scheduledAt: { gte: startOfDay, lte: endOfDay },
        status: { notIn: ['CANCELADO', 'RECUSADO'] },
      },
      select: { id: true, scheduledAt: true },
    });

    const slots: TimeSlot[] = rawSlots.map((time) => {
      const block = this.blockedSlots.find(
        (b) =>
          b.establishmentId === establishmentId &&
          b.date === date &&
          b.time === time,
      );
      if (block) {
        return {
          time,
          available: false,
          reason: block.reason,
          blockId: block.id,
        };
      }

      const booking = dayBookings.find((b) => {
        const t = b.scheduledAt;
        const bTime = `${String(t.getUTCHours()).padStart(2, '0')}:${String(t.getUTCMinutes()).padStart(2, '0')}`;
        return bTime === time;
      });
      if (booking) {
        return {
          time,
          available: false,
          reason: 'Agendamento',
          bookingId: booking.id,
        };
      }

      return { time, available: true };
    });

    return { date, slots };
  }

  blockSlot(data: {
    establishmentId: string;
    date: string;
    time: string;
    reason?: string;
  }): BlockedSlot {
    this.blockedSlots = this.blockedSlots.filter(
      (b) =>
        !(
          b.establishmentId === data.establishmentId &&
          b.date === data.date &&
          b.time === data.time
        ),
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
    const idx = this.blockedSlots.findIndex(
      (b) => b.id === id && !b.isAutomatic,
    );
    if (idx !== -1) {
      this.blockedSlots.splice(idx, 1);
      this.persistBlocked();
    }
  }

  getBlockedSlots(establishmentId: string, date?: string): BlockedSlot[] {
    return this.blockedSlots.filter(
      (b) =>
        b.establishmentId === establishmentId && (!date || b.date === date),
    );
  }

  async getEstabStats(establishmentId: string) {
    const now = new Date();
    const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1);

    const [totalBookings, monthBookings, revenueAgg, monthRevenueAgg] =
      await Promise.all([
        this.prisma.booking.count({
          where: {
            establishmentId,
            status: { notIn: ['CANCELADO', 'RECUSADO'] },
          },
        }),
        this.prisma.booking.count({
          where: {
            establishmentId,
            status: { notIn: ['CANCELADO', 'RECUSADO'] },
            scheduledAt: { gte: startOfMonth },
          },
        }),
        this.prisma.booking.aggregate({
          where: { establishmentId, status: 'CONCLUIDO' },
          _sum: { price: true },
          _avg: { price: true },
        }),
        this.prisma.booking.aggregate({
          where: {
            establishmentId,
            status: 'CONCLUIDO',
            scheduledAt: { gte: startOfMonth },
          },
          _sum: { price: true },
        }),
      ]);

    const totalRevenue = revenueAgg._sum.price ?? 0;
    const avgTicket = revenueAgg._avg.price ?? 0;
    const monthRevenue = monthRevenueAgg._sum.price ?? 0;

    const sixMonthsAgo = new Date(now.getFullYear(), now.getMonth() - 5, 1);
    const concludedInPeriod = await this.prisma.booking.findMany({
      where: {
        establishmentId,
        status: 'CONCLUIDO',
        scheduledAt: { gte: sixMonthsAgo },
      },
      select: { scheduledAt: true, price: true },
    });

    const monthMap = new Map<string, number>();
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      monthMap.set(`${d.getFullYear()}-${d.getMonth()}`, 0);
    }
    for (const b of concludedInPeriod) {
      const key = `${b.scheduledAt.getFullYear()}-${b.scheduledAt.getMonth()}`;
      if (monthMap.has(key)) {
        monthMap.set(key, (monthMap.get(key) ?? 0) + b.price);
      }
    }
    const last6Months = Array.from(monthMap.entries()).map(([key, value]) => {
      const month = parseInt(key.split('-')[1]);
      return { month: PT_MONTHS[month], value };
    });

    const allActive = await this.prisma.booking.findMany({
      where: {
        establishmentId,
        status: { notIn: ['CANCELADO', 'RECUSADO'] },
      },
      select: { serviceName: true },
    });
    const svcCount = new Map<string, number>();
    for (const b of allActive) {
      svcCount.set(b.serviceName, (svcCount.get(b.serviceName) ?? 0) + 1);
    }
    const topServices = Array.from(svcCount.entries())
      .sort((a, b) => b[1] - a[1])
      .slice(0, 5)
      .map(([name, count]) => ({ name, count }));

    return {
      totalBookings,
      monthBookings,
      totalRevenue,
      monthRevenue,
      avgTicket,
      last6Months,
      topServices,
    };
  }
}
