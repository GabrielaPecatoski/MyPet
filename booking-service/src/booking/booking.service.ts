import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { ClientProxy } from '@nestjs/microservices';
import { Booking } from './entities/booking.entity';
import { CreateBookingDto } from './dto/create-booking.dto';
import { EVENTS } from '../events/events.constants';

@Injectable()
export class BookingService {
  constructor(
    @InjectRepository(Booking)
    private readonly bookingRepo: Repository<Booking>,
    @Inject('RABBITMQ_CLIENT')
    private readonly rabbitClient: ClientProxy,
  ) {}

  findByUser(userId: string): Promise<Booking[]> {
    return this.bookingRepo.find({ where: { userId }, order: { createdAt: 'DESC' } });
  }

  findByEstablishment(establishmentId: string): Promise<Booking[]> {
    return this.bookingRepo.find({ where: { establishmentId }, order: { createdAt: 'DESC' } });
  }

  async findById(id: string): Promise<Booking> {
    const booking = await this.bookingRepo.findOne({ where: { id } });
    if (!booking) throw new NotFoundException('Agendamento não encontrado');
    return booking;
  }

  async create(dto: CreateBookingDto): Promise<Booking> {
    const booking = this.bookingRepo.create({ ...dto, status: 'PENDENTE' });
    const saved = await this.bookingRepo.save(booking);
    try {
      this.rabbitClient.emit(EVENTS.BOOKING_CREATED, {
        bookingId: saved.id,
        userId: saved.userId,
        establishmentOwnerId: saved.establishmentOwnerId,
        establishmentId: saved.establishmentId,
        scheduledAt: saved.scheduledAt,
        status: 'PENDENTE',
      });
    } catch (_) {}
    return saved;
  }

  async confirm(id: string): Promise<Booking> {
    const booking = await this.findById(id);
    booking.status = 'CONFIRMADO';
    const saved = await this.bookingRepo.save(booking);
    try {
      this.rabbitClient.emit(EVENTS.BOOKING_CONFIRMED, {
        bookingId: id,
        userId: saved.userId,
        establishmentId: saved.establishmentId,
        scheduledAt: saved.scheduledAt,
      });
    } catch (_) {}
    return saved;
  }

  async cancel(id: string, reason?: string): Promise<Booking> {
    const booking = await this.findById(id);
    booking.status = 'CANCELADO';
    if (reason) booking.cancelReason = reason;
    const saved = await this.bookingRepo.save(booking);
    try {
      this.rabbitClient.emit(EVENTS.BOOKING_CANCELLED, {
        bookingId: id,
        userId: saved.userId,
        establishmentOwnerId: saved.establishmentOwnerId,
        reason: reason ?? null,
      });
    } catch (_) {}
    return saved;
  }

  async complete(id: string): Promise<Booking> {
    const booking = await this.findById(id);
    booking.status = 'CONCLUIDO';
    const saved = await this.bookingRepo.save(booking);
    try {
      this.rabbitClient.emit(EVENTS.BOOKING_COMPLETED, {
        bookingId: id,
        userId: saved.userId,
        completedAt: new Date().toISOString(),
      });
    } catch (_) {}
    return saved;
  }

  async remove(id: string): Promise<void> {
    const booking = await this.findById(id);
    await this.bookingRepo.remove(booking);
  }
}
