import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { BookingService } from "@booking/bookings/application/services/booking.service";

/**
 * Varredura periódica que cancela agendamentos expirados (AGUARDANDO_PAGAMENTO
 * há mais de 1h) sem depender do usuário abrir a agenda. Usa setInterval para
 * evitar adicionar a dependência @nestjs/schedule só por causa de um job.
 */
@Injectable()
export class ExpiredBookingScheduler implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(ExpiredBookingScheduler.name);
  private readonly intervalMs = 60 * 1000;
  private timer?: NodeJS.Timeout;

  constructor(private readonly bookingService: BookingService) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      this.bookingService
        .cancelExpired()
        .catch((err) => this.logger.warn(`Falha ao cancelar expirados: ${err}`));
    }, this.intervalMs);
    // Não bloqueia o encerramento do processo.
    this.timer.unref?.();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }
}
