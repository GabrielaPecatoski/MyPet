import { Inject, Injectable } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { RABBITMQ_CLIENT } from './app.module';
import { EVENTS } from './events/events.constants';

@Injectable()
export class AppService {
  constructor(
    @Inject(RABBITMQ_CLIENT) private readonly rabbitClient: ClientProxy,
  ) {}

  async createBooking(data: {
    bookingId: string; userId: string;
    petId: string; serviceId: string;
    establishmentId: string; scheduledAt: string;
  }) {
    // TODO: salvar no banco (TypeORM)
    this.rabbitClient.emit(EVENTS.BOOKING_CREATED, {
      bookingId: data.bookingId,
      userId: data.userId,
      establishmentId: data.establishmentId,
      scheduledAt: data.scheduledAt,
    });
    return { message: 'Agendamento criado', bookingId: data.bookingId };
  }

  async updateBookingStatus(bookingId: string, status: 'CONFIRMED' | 'CANCELED') {
    // TODO: atualizar no banco
    this.rabbitClient.emit(EVENTS.BOOKING_STATUS_UPDATED, {
      bookingId, status, updatedAt: new Date().toISOString(),
    });
    return { message: `Status atualizado para ${status}`, bookingId };
  }

  async completeBooking(bookingId: string) {
    // TODO: atualizar no banco
    this.rabbitClient.emit(EVENTS.BOOKING_COMPLETED, {
      bookingId, completedAt: new Date().toISOString(),
    });
    return { message: 'Atendimento finalizado', bookingId };
  }
}