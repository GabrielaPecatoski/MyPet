import { BookingDto } from "@booking/bookings/application/dto/booking.dto";
import { CreateBookingDto } from "@booking/bookings/application/dto/create-booking.dto";
import {
  Booking,
  type BookingStatus,
} from "@booking/bookings/domain/models/booking.entity";
import {
  BOOKING_REPOSITORY,
  type BookingRepository,
} from "@booking/bookings/domain/repositories/booking-repository.interface";
import {
  Inject,
  Injectable,
  Logger,
  NotFoundException,
  OnModuleDestroy,
  OnModuleInit,
} from "@nestjs/common";
import {
  BookingExchangeName,
  BookingRoutingKey,
} from "@shared/contracts/events/booking-events.enum";
import { SharedMessagingService } from "@shared/infra/messaging/shared-messaging.service";

@Injectable()
export class BookingService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(BookingService.name);
  private reminderInterval?: ReturnType<typeof setInterval>;
  private readonly remindedIds = new Set<string>();

  constructor(
    @Inject(BOOKING_REPOSITORY)
    private readonly repo: BookingRepository,
    private readonly messaging: SharedMessagingService,
  ) {}

  onModuleInit() {
    // Check every hour for bookings within 24h window
    this.reminderInterval = setInterval(
      () => void this.sendReminders(),
      60 * 60 * 1000,
    );
  }

  onModuleDestroy() {
    if (this.reminderInterval) clearInterval(this.reminderInterval);
  }

  private async sendReminders(): Promise<void> {
    try {
      const now = new Date();
      const from = new Date(now.getTime() + 23 * 60 * 60 * 1000);
      const to = new Date(now.getTime() + 25 * 60 * 60 * 1000);
      const upcoming = await this.repo.findUpcoming(from, to);

      for (const booking of upcoming) {
        if (!booking.id || this.remindedIds.has(booking.id)) continue;
        this.remindedIds.add(booking.id);
        await this.safePublish(
          BookingExchangeName.REMINDER,
          BookingRoutingKey.REMINDER,
          {
            bookingId: booking.id,
            userId: booking.userId,
            serviceName: booking.serviceName,
            establishmentName: booking.establishmentName,
            scheduledAt: booking.scheduledAt.toISOString(),
          },
        );
      }
    } catch (err) {
      this.logger.warn(`Reminder scheduler error: ${err}`);
    }
  }

  async create(
    userId: string,
    userEmail: string,
    dto: CreateBookingDto,
  ): Promise<BookingDto> {
    const services =
      dto.services && dto.services.length > 0 ? dto.services : undefined;
    const totalPrice = services
      ? services.reduce((s, svc) => s + svc.price, 0)
      : (dto.price ?? 0);
    const displayName =
      services && services.length > 1
        ? services.map((s) => s.name).join(", ")
        : (dto.serviceName ?? services?.[0]?.name ?? "");

    const booking = Booking.restore({
      userId,
      userName: dto.userName ?? userEmail,
      petId: dto.petId,
      petName: dto.petName,
      serviceName: displayName,
      servicesJson: services ? JSON.stringify(services) : undefined,
      establishmentId: dto.establishmentId,
      establishmentName: dto.establishmentName,
      scheduledAt: new Date(dto.scheduledAt),
      price: totalPrice,
      status: "PENDENTE",
    })!;
    await this.repo.create(booking);
    await this.safePublish(
      BookingExchangeName.CREATED,
      BookingRoutingKey.CREATED,
      {
        bookingId: booking.id!,
        establishmentId: booking.establishmentId,
        clientName: booking.userName,
        userEmail,
        serviceName: booking.serviceName,
        scheduledAt: booking.scheduledAt.toISOString(),
      },
    );
    return BookingDto.fromBooking(booking)!;
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

  async updateStatus(id: string, status: BookingStatus): Promise<BookingDto> {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException("Agendamento não encontrado");
    booking.withStatus(status);
    await this.repo.update(booking);

    if (status === "CONFIRMADO" || status === "RECUSADO") {
      await this.safePublish(
        BookingExchangeName.STATUS_UPDATED,
        BookingRoutingKey.STATUS_UPDATED,
        {
          bookingId: booking.id!,
          userId: booking.userId,
          status,
          establishmentName: booking.establishmentName,
        },
      );
    } else if (status === "CONCLUIDO") {
      await this.safePublish(
        BookingExchangeName.COMPLETED,
        BookingRoutingKey.COMPLETED,
        {
          bookingId: booking.id!,
          userId: booking.userId,
          establishmentName: booking.establishmentName,
          serviceName: booking.serviceName,
        },
      );
    } else if (status === "CANCELADO") {
      await this.safePublish(
        BookingExchangeName.CANCELED,
        BookingRoutingKey.CANCELED,
        {
          bookingId: booking.id!,
          userId: booking.userId,
          serviceName: booking.serviceName,
          establishmentName: booking.establishmentName,
        },
      );
    }
    return BookingDto.fromBooking(booking)!;
  }

  async cancel(id: string): Promise<BookingDto> {
    return this.updateStatus(id, "CANCELADO");
  }

  async complete(id: string): Promise<BookingDto> {
    return this.updateStatus(id, "CONCLUIDO");
  }

  async remove(id: string): Promise<void> {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException("Agendamento não encontrado");
    await this.repo.delete(id);
  }

  async getStats(establishmentId: string) {
    const rows = await this.repo.findByEstablishmentId(establishmentId);
    const now = new Date();
    const thisMonth = now.getMonth();
    const thisYear = now.getFullYear();

    const totalBookings = rows.length;
    const monthBookings = rows.filter((b) => {
      const d = b.scheduledAt;
      return d.getMonth() === thisMonth && d.getFullYear() === thisYear;
    }).length;

    const completed = rows.filter((b) => b.status === "CONCLUIDO");
    const totalRevenue = completed.reduce((s, b) => s + b.price, 0);
    const monthCompleted = completed.filter((b) => {
      const d = b.scheduledAt;
      return d.getMonth() === thisMonth && d.getFullYear() === thisYear;
    });
    const monthRevenue = monthCompleted.reduce((s, b) => s + b.price, 0);
    const avgTicket =
      completed.length > 0 ? totalRevenue / completed.length : 0;

    const ptMonths = [
      "Jan",
      "Fev",
      "Mar",
      "Abr",
      "Mai",
      "Jun",
      "Jul",
      "Ago",
      "Set",
      "Out",
      "Nov",
      "Dez",
    ];
    const last6Months = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(thisYear, thisMonth - i, 1);
      const m = d.getMonth();
      const y = d.getFullYear();
      const monthRows = completed.filter(
        (b) =>
          b.scheduledAt.getMonth() === m && b.scheduledAt.getFullYear() === y,
      );
      last6Months.push({
        month: ptMonths[m],
        value: monthRows.reduce((s, b) => s + b.price, 0),
      });
    }

    const serviceCount: Record<string, number> = {};
    for (const b of rows) {
      serviceCount[b.serviceName] = (serviceCount[b.serviceName] ?? 0) + 1;
    }
    const topServices = Object.entries(serviceCount)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([name, count]) => ({ name, count }));

    return {
      totalRevenue,
      monthRevenue,
      avgTicket,
      totalBookings,
      monthBookings,
      last6Months,
      topServices,
    };
  }

  private async safePublish(
    exchange: string,
    routingKey: string,
    payload: unknown,
  ): Promise<void> {
    try {
      await this.messaging.assertExchange(exchange, "direct");
      await this.messaging.publish(exchange, routingKey, payload);
    } catch (err) {
      this.logger.warn(`RabbitMQ publish failed [${routingKey}]: ${err}`);
    }
  }
}
