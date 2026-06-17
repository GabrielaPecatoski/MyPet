import { BookingService } from "@booking/bookings/application/services/booking.service";
import {
  Injectable,
  Logger,
  OnModuleDestroy,
  OnModuleInit,
} from "@nestjs/common";

@Injectable()
export class TodayBookingReminderScheduler
  implements OnModuleInit, OnModuleDestroy
{
  private readonly logger = new Logger(TodayBookingReminderScheduler.name);
  private readonly intervalMs = 60 * 60 * 1000;
  private timer?: NodeJS.Timeout;

  constructor(private readonly bookingService: BookingService) {}

  onModuleInit(): void {
    this.timer = setInterval(() => {
      this.bookingService
        .notifyTodayBookings()
        .catch((err) =>
          this.logger.warn(`Falha ao notificar agendamentos de hoje: ${err}`),
        );
    }, this.intervalMs);
    this.timer.unref?.();
  }

  onModuleDestroy(): void {
    if (this.timer) clearInterval(this.timer);
  }
}
