import { CreateBookingDto } from "@booking/bookings/application/dto/create-booking.dto";
import { BookingDto } from "@booking/bookings/application/dto/booking.dto";
import { Booking, type BookingStatus } from "@booking/bookings/domain/models/booking.entity";
import {
  BOOKING_REPOSITORY,
  type BookingRepository,
} from "@booking/bookings/domain/repositories/booking-repository.interface";
import { Inject, Injectable, Logger, NotFoundException } from "@nestjs/common";
import { SharedMessagingService } from "@shared/infra/messaging/shared-messaging.service";
import { BookingExchangeName, BookingRoutingKey } from "@shared/contracts/events/booking-events.enum";

@Injectable()
export class BookingService {
  private readonly logger = new Logger(BookingService.name);

  constructor(
    @Inject(BOOKING_REPOSITORY)
    private readonly repo: BookingRepository,
    private readonly messaging: SharedMessagingService,
  ) {}

  async create(userId: string, userName: string, dto: CreateBookingDto): Promise<void> {
    const booking = Booking.restore({
      userId,
      userName: dto.userName ?? userName,
      petId: dto.petId,
      petName: dto.petName,
      serviceName: dto.serviceName,
      establishmentId: dto.establishmentId,
      establishmentName: dto.establishmentName,
      scheduledAt: new Date(dto.scheduledAt),
      price: dto.price ?? 0,
      status: "PENDENTE",
    })!;
    await this.repo.create(booking);
    await this.safePublish(BookingExchangeName.CREATED, BookingRoutingKey.CREATED, {
      bookingId: booking.id!,
      establishmentId: booking.establishmentId,
      clientName: booking.userName,
      serviceName: booking.serviceName,
      scheduledAt: booking.scheduledAt.toISOString(),
    });
  }

  async findByUser(userId: string): Promise<BookingDto[]> {
    const rows = await this.repo.findByUserId(userId);
    return rows.map((b) => BookingDto.fromBooking(b)!);
  }

  async findByEstablishment(establishmentId: string): Promise<BookingDto[]> {
    const rows = await this.repo.findByEstablishmentId(establishmentId);
    return rows.map((b) => BookingDto.fromBooking(b)!);
  }

  async findById(id: string): Promise<BookingDto | null> {
    return BookingDto.fromBooking(await this.repo.findById(id));
  }

  async updateStatus(id: string, status: BookingStatus): Promise<void> {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException("Agendamento não encontrado");
    booking.withStatus(status);
    await this.repo.update(booking);

    if (status === "CONFIRMADO" || status === "RECUSADO") {
      await this.safePublish(BookingExchangeName.STATUS_UPDATED, BookingRoutingKey.STATUS_UPDATED, {
        bookingId: booking.id!,
        userId: booking.userId,
        status,
        establishmentName: booking.establishmentName,
      });
    } else if (status === "CONCLUIDO") {
      await this.safePublish(BookingExchangeName.COMPLETED, BookingRoutingKey.COMPLETED, {
        bookingId: booking.id!,
        userId: booking.userId,
        establishmentName: booking.establishmentName,
        serviceName: booking.serviceName,
      });
    } else if (status === "CANCELADO") {
      await this.safePublish(BookingExchangeName.CANCELED, BookingRoutingKey.CANCELED, {
        bookingId: booking.id!,
        userId: booking.userId,
      });
    }
  }

  async cancel(id: string): Promise<void> {
    return this.updateStatus(id, "CANCELADO");
  }

  async complete(id: string): Promise<void> {
    return this.updateStatus(id, "CONCLUIDO");
  }

  async remove(id: string): Promise<void> {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException("Agendamento não encontrado");
    await this.repo.delete(id);
  }

  private async safePublish(exchange: string, routingKey: string, payload: unknown): Promise<void> {
    try {
      await this.messaging.assertExchange(exchange, "direct");
      await this.messaging.publish(exchange, routingKey, payload);
    } catch (err) {
      this.logger.warn(`RabbitMQ publish failed [${routingKey}]: ${err}`);
    }
  }
}
