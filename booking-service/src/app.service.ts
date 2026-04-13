import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { RABBITMQ_CLIENT } from './app.module';
import { EVENTS } from './events/events.constants';
import * as crypto from 'crypto';

export interface Booking {
  id: string;
  userId: string;
  petId: string;
  petName: string;
  serviceName: string;
  establishmentId: string;
  establishmentName: string;
  scheduledAt: string;
  status: 'PENDENTE' | 'CONFIRMADO' | 'RECUSADO' | 'CONCLUIDO';
  createdAt: string;
}

@Injectable()
export class AppService {
  private bookings: Booking[] = [
    {
      id: 'book-001',
      userId: 'cliente-001',
      petId: 'pet-001',
      petName: 'Rex',
      serviceName: 'Banho e Tosa',
      establishmentId: 'estab-001',
      establishmentName: 'Pet Shop Amor & Carinho',
      scheduledAt: '2026-04-15T10:00:00.000Z',
      status: 'CONFIRMADO',
      createdAt: new Date().toISOString(),
    },
    {
      id: 'book-002',
      userId: 'cliente-001',
      petId: 'pet-002',
      petName: 'Luna',
      serviceName: 'Consulta Veterinária',
      establishmentId: 'estab-001',
      establishmentName: 'Pet Shop Amor & Carinho',
      scheduledAt: '2026-04-18T14:30:00.000Z',
      status: 'PENDENTE',
      createdAt: new Date().toISOString(),
    },
  ];

  constructor(
    @Inject(RABBITMQ_CLIENT) private readonly rabbitClient: ClientProxy,
  ) {}

  findByUser(userId: string): Booking[] {
    return this.bookings.filter((b) => b.userId === userId);
  }

  findByEstablishment(establishmentId: string): Booking[] {
    return this.bookings.filter((b) => b.establishmentId === establishmentId);
  }

  findById(id: string): Booking {
    const b = this.bookings.find((b) => b.id === id);
    if (!b) throw new NotFoundException('Agendamento não encontrado');
    return b;
  }

  async createBooking(data: {
    userId: string;
    petId: string;
    petName: string;
    serviceName: string;
    establishmentId: string;
    establishmentName: string;
    scheduledAt: string;
  }): Promise<Booking> {
    const booking: Booking = {
      id: crypto.randomUUID(),
      ...data,
      status: 'PENDENTE',
      createdAt: new Date().toISOString(),
    };
    this.bookings.push(booking);

    try {
      this.rabbitClient.emit(EVENTS.BOOKING_CREATED, {
        bookingId: booking.id,
        userId: booking.userId,
        establishmentId: booking.establishmentId,
        scheduledAt: booking.scheduledAt,
      });
    } catch (_) {}

    return booking;
  }

  async updateStatus(id: string, status: 'CONFIRMADO' | 'RECUSADO'): Promise<Booking> {
    const idx = this.bookings.findIndex((b) => b.id === id);
    if (idx === -1) throw new NotFoundException('Agendamento não encontrado');
    this.bookings[idx].status = status;

    try {
      this.rabbitClient.emit(EVENTS.BOOKING_STATUS_UPDATED, {
        bookingId: id,
        status,
        updatedAt: new Date().toISOString(),
      });
    } catch (_) {}

    return this.bookings[idx];
  }

  async completeBooking(id: string): Promise<Booking> {
    const idx = this.bookings.findIndex((b) => b.id === id);
    if (idx === -1) throw new NotFoundException('Agendamento não encontrado');
    this.bookings[idx].status = 'CONCLUIDO';

    try {
      this.rabbitClient.emit(EVENTS.BOOKING_COMPLETED, {
        bookingId: id,
        completedAt: new Date().toISOString(),
      });
    } catch (_) {}

    return this.bookings[idx];
  }

  removeBooking(id: string): void {
    const idx = this.bookings.findIndex((b) => b.id === id);
    if (idx === -1) throw new NotFoundException('Agendamento não encontrado');
    this.bookings.splice(idx, 1);
  }
}
