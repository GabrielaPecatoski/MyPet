import { BookingService } from "@booking/bookings/application/services/booking.service";
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from "@nestjs/common";

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
        .catch((err) =>
          this.logger.warn(`Falha ao cancelar expirados: ${err}`),
        );
    }, this.intervalMs);
    this.timer.unref?.();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }
}
