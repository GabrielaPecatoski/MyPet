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

  async create(userId: string, userName: string, dto: CreateBookingDto): Promise<BookingDto> {
    const services = dto.services && dto.services.length > 0 ? dto.services : undefined;
    const totalPrice = services ? services.reduce((s, svc) => s + svc.price, 0) : (dto.price ?? 0);
    const displayName = services && services.length > 1
      ? services.map((s) => s.name).join(", ")
      : (dto.serviceName ?? services?.[0]?.name ?? "");

    const booking = Booking.restore({
      userId,
      userName: dto.userName ?? userName,
      petId: dto.petId,
      petName: dto.petName,
      serviceName: displayName,
      servicesJson: services ? JSON.stringify(services) : undefined,
      establishmentId: dto.establishmentId,
      establishmentName: dto.establishmentName,
      scheduledAt: new Date(dto.scheduledAt),
      price: totalPrice,
      status: "AGUARDANDO_PAGAMENTO",
    })!;
    const created = await this.repo.create(booking);
    return BookingDto.fromBooking(created)!;
  }

  async findByUser(userId: string): Promise<BookingDto[]> {
    const rows = await this.repo.findByUserId(userId);
    const now = new Date();
    for (const b of rows) {
      if (b.status === "AGUARDANDO_PAGAMENTO" && b.createdAt) {
        const expiresAt = new Date(b.createdAt.getTime() + 60 * 60 * 1000);
        if (expiresAt < now) {
          b.withStatus("CANCELADO");
          await this.repo.update(b);
        }
      }
    }
    return rows.map((b) => BookingDto.fromBooking(b)!);
  }

  async findByEstablishment(establishmentId: string): Promise<BookingDto[]> {
    const rows = await this.repo.findByEstablishmentId(establishmentId);
    return rows
      .filter((b) => b.status !== "AGUARDANDO_PAGAMENTO" && b.paymentStatus !== "NONE")
      .map((b) => BookingDto.fromBooking(b)!);
  }

  async pay(id: string, method: string, cardNumber?: string, installments?: number): Promise<{ booking: BookingDto; payment: Record<string, unknown> }> {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException("Agendamento não encontrado");

    if (booking.paymentStatus === "AUTHORIZED" || booking.paymentStatus === "CAPTURED") {
      return { booking: BookingDto.fromBooking(booking)!, payment: { status: "APPROVED", method, amount: booking.price, alreadyPaid: true } };
    }

    const payment = this.simulatePayment(method, booking.price, cardNumber, installments);

    if (payment["status"] === "APPROVED") {
      booking.withStatus("PENDENTE").withPayment("AUTHORIZED", method);
      await this.repo.update(booking);
      // Não aguarda o broker: a resposta do pagamento não pode ficar presa
      // numa conexão lenta/instável com o RabbitMQ (causava timeout no app).
      void this.safePublish(BookingExchangeName.CREATED, BookingRoutingKey.CREATED, {
        bookingId: booking.id!,
        establishmentId: booking.establishmentId,
        clientName: booking.userName,
        serviceName: booking.serviceName,
        scheduledAt: booking.scheduledAt.toISOString(),
      });
    }

    return { booking: BookingDto.fromBooking(booking)!, payment };
  }

  private simulatePayment(method: string, amount: number, cardNumber?: string, installments?: number): Record<string, unknown> {
    const base = { method, amount };

    if (method === "PIX") {
      return { ...base, status: "APPROVED", pixKey: "mypet@pagamentos.com" };
    }
    if (method === "BOLETO") {
      const code = "34191.75501 34191.75501 34191.75501 1 " + String(Math.floor(amount * 100)).padStart(14, "0");
      return { ...base, status: "APPROVED", boletoCode: code };
    }
    if (method === "CREDIT_CARD") {
      const lastFour = cardNumber ? cardNumber.slice(-4) : "0000";
      if (Math.random() < 0.05) {
        return { ...base, status: "REJECTED", rejectionReason: "Cartão recusado pela operadora." };
      }
      return { ...base, status: "APPROVED", cardLastFour: lastFour, installments: installments ?? 1 };
    }
    if (method === "DEBIT_CARD") {
      const lastFour = cardNumber ? cardNumber.slice(-4) : "0000";
      return { ...base, status: "APPROVED", cardLastFour: lastFour };
    }
    return { ...base, status: "APPROVED" };
  }

  async findById(id: string): Promise<BookingDto | null> {
    return BookingDto.fromBooking(await this.repo.findById(id));
  }

  async updateStatus(id: string, status: BookingStatus): Promise<BookingDto> {
    const booking = await this.repo.findById(id);
    if (!booking) throw new NotFoundException("Agendamento não encontrado");
    booking.withStatus(status);

    // Escrow: estorna o valor retido ao recusar/cancelar; captura ao concluir.
    if ((status === "RECUSADO" || status === "CANCELADO") && booking.paymentStatus === "AUTHORIZED") {
      booking.withPayment("REFUNDED");
    } else if (status === "CONCLUIDO" && booking.paymentStatus === "AUTHORIZED") {
      booking.withPayment("CAPTURED");
    }

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
    return BookingDto.fromBooking(booking)!;
  }

  async cancel(id: string): Promise<BookingDto> {
    return this.updateStatus(id, "CANCELADO");
  }

  /**
   * Cancela em background os agendamentos que ficaram em AGUARDANDO_PAGAMENTO
   * por mais de 1 hora. Roda periodicamente, independente do usuário abrir a agenda.
   * Retorna a quantidade de agendamentos cancelados.
   */
  async cancelExpired(): Promise<number> {
    const cutoff = new Date(Date.now() - 60 * 60 * 1000);
    const expired = await this.repo.findExpiredAwaitingPayment(cutoff);
    for (const b of expired) {
      b.withStatus("CANCELADO");
      await this.repo.update(b);
    }
    if (expired.length > 0) {
      this.logger.log(`${expired.length} agendamento(s) expirado(s) cancelado(s) automaticamente.`);
    }
    return expired.length;
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
    const avgTicket = completed.length > 0 ? totalRevenue / completed.length : 0;

    const ptMonths = ["Jan", "Fev", "Mar", "Abr", "Mai", "Jun", "Jul", "Ago", "Set", "Out", "Nov", "Dez"];
    const last6Months = [];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(thisYear, thisMonth - i, 1);
      const m = d.getMonth();
      const y = d.getFullYear();
      const monthRows = completed.filter((b) => b.scheduledAt.getMonth() === m && b.scheduledAt.getFullYear() === y);
      last6Months.push({ month: ptMonths[m], value: monthRows.reduce((s, b) => s + b.price, 0) });
    }

    const serviceCount: Record<string, number> = {};
    for (const b of rows) {
      serviceCount[b.serviceName] = (serviceCount[b.serviceName] ?? 0) + 1;
    }
    const topServices = Object.entries(serviceCount)
      .sort(([, a], [, b]) => b - a)
      .slice(0, 5)
      .map(([name, count]) => ({ name, count }));

    return { totalRevenue, monthRevenue, avgTicket, totalBookings, monthBookings, last6Months, topServices };
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
