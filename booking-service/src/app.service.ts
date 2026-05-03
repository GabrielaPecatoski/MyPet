import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { PrismaService } from './prisma.service';
import { RABBITMQ_CLIENT } from './constants';
import { EVENTS } from './events/events.constants';

@Injectable()
export class AppService {
  private readonly logger = new Logger(AppService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(RABBITMQ_CLIENT) private readonly rabbitClient: ClientProxy,
  ) {}

  async findByUser(userId: string) {
    return this.prisma.booking.findMany({
      where: { userId },
      orderBy: { scheduledAt: 'desc' },
    });
  }

  async findByEstablishment(establishmentId: string) {
    return this.prisma.booking.findMany({
      where: { establishmentId },
      orderBy: { scheduledAt: 'desc' },
    });
  }

  async findById(id: string) {
    const b = await this.prisma.booking.findUnique({ where: { id } });
    if (!b) throw new NotFoundException('Agendamento não encontrado');
    return b;
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
  }) {
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

    try {
      this.rabbitClient.emit(EVENTS.BOOKING_CREATED, {
        bookingId: booking.id,
        userId: booking.userId,
        establishmentId: booking.establishmentId,
        scheduledAt: booking.scheduledAt.toISOString(),
      });
    } catch (err) {
      this.logger.warn(`Falha ao emitir BOOKING_CREATED: ${err}`);
    }

    return booking;
  }

  async updateStatus(id: string, status: 'CONFIRMADO' | 'RECUSADO') {
    await this.findById(id);
    const booking = await this.prisma.booking.update({ where: { id }, data: { status } });

    try {
      this.rabbitClient.emit(EVENTS.BOOKING_STATUS_UPDATED, {
        bookingId: id,
        status,
        updatedAt: new Date().toISOString(),
      });
    } catch (err) {
      this.logger.warn(`Falha ao emitir BOOKING_STATUS_UPDATED: ${err}`);
    }

    return booking;
  }

  async completeBooking(id: string) {
    await this.findById(id);
    const booking = await this.prisma.booking.update({
      where: { id },
      data: { status: 'CONCLUIDO' },
    });

    try {
      this.rabbitClient.emit(EVENTS.BOOKING_COMPLETED, {
        bookingId: id,
        completedAt: new Date().toISOString(),
      });
    } catch (err) {
      this.logger.warn(`Falha ao emitir BOOKING_COMPLETED: ${err}`);
    }

    return booking;
  }

  async removeBooking(id: string) {
    await this.findById(id);
    await this.prisma.booking.delete({ where: { id } });
  }
}
