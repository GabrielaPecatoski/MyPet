import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { NotificationService } from "@notification/application/services/notification.service";
import { MailService } from "@notification/infra/mail/mail.service";
import { FcmService } from "@notification/infra/push/fcm.service";
import { DeviceTokenRepository } from "@notification/infra/repositories/device-token.repository";
import {
  BookingExchangeName,
  BookingRoutingKey,
} from "@shared/contracts/events/booking-events.enum";
import {
  MarketplaceExchangeName,
  MarketplaceRoutingKey,
} from "@shared/contracts/events/marketplace-events.enum";
import {
  ReviewExchangeName,
  ReviewRoutingKey,
} from "@shared/contracts/events/review-events.enum";
import {
  UserAuthExchangeName,
  UserAuthRoutingKey,
} from "@shared/contracts/events/user-auth-events.enum";
import { RabbitMQService } from "@shared/infra/messaging/rabbitmq.service";

interface BookingCreatedPayload {
  bookingId: string;
  establishmentId: string;
  clientName: string;
  userEmail?: string;
  serviceName: string;
  scheduledAt: string;
}

interface BookingStatusUpdatedPayload {
  bookingId: string;
  userId: string;
  status: string;
  establishmentName: string;
}

interface BookingCanceledPayload {
  bookingId: string;
  userId: string;
  serviceName: string;
  establishmentName: string;
}

interface BookingCompletedPayload {
  bookingId: string;
  userId: string;
  establishmentName: string;
  serviceName: string;
}

interface BookingReminderPayload {
  bookingId: string;
  userId: string;
  serviceName: string;
  establishmentName: string;
  scheduledAt: string;
}

interface OrderCreatedPayload {
  orderId: string;
  userId: string;
  userEmail?: string;
  total: number;
  itemCount: number;
}

interface ReviewCreatedPayload {
  reviewId: string;
  establishmentId: string;
  userId: string;
  rating: number;
}

interface UserCreatedPayload {
  userId: string;
  name: string;
  email: string;
}

const NOTIFICATION_QUEUE = "notification.service.queue";

@Injectable()
export class NotificationHandler implements OnModuleInit {
  private readonly logger = new Logger(NotificationHandler.name);

  constructor(
    private readonly rabbitMQService: RabbitMQService,
    private readonly notificationService: NotificationService,
    private readonly deviceTokenRepo: DeviceTokenRepository,
    private readonly mailService: MailService,
    private readonly fcmService: FcmService,
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      const channel = this.rabbitMQService.getChannel();
      await channel.assertQueue(NOTIFICATION_QUEUE, { durable: true });

      const bindings: { exchange: string; routingKey: string }[] = [
        {
          exchange: BookingExchangeName.CREATED,
          routingKey: BookingRoutingKey.CREATED,
        },
        {
          exchange: BookingExchangeName.STATUS_UPDATED,
          routingKey: BookingRoutingKey.STATUS_UPDATED,
        },
        {
          exchange: BookingExchangeName.COMPLETED,
          routingKey: BookingRoutingKey.COMPLETED,
        },
        {
          exchange: BookingExchangeName.CANCELED,
          routingKey: BookingRoutingKey.CANCELED,
        },
        {
          exchange: BookingExchangeName.REMINDER,
          routingKey: BookingRoutingKey.REMINDER,
        },
        {
          exchange: MarketplaceExchangeName.ORDER_CREATED,
          routingKey: MarketplaceRoutingKey.ORDER_CREATED,
        },
        {
          exchange: ReviewExchangeName.CREATED,
          routingKey: ReviewRoutingKey.CREATED,
        },
        {
          exchange: UserAuthExchangeName.USER_CREATED,
          routingKey: UserAuthRoutingKey.USER_CREATED,
        },
      ];

      for (const { exchange, routingKey } of bindings) {
        await channel.assertExchange(exchange, "direct", { durable: true });
        await channel.bindQueue(NOTIFICATION_QUEUE, exchange, routingKey);
      }

      await channel.consume(NOTIFICATION_QUEUE, async (msg) => {
        if (!msg) return;
        try {
          const routingKey = msg.fields.routingKey;
          const payload = JSON.parse(msg.content.toString()) as unknown;
          await this.handleMessage(routingKey, payload);
          channel.ack(msg);
        } catch (err) {
          this.logger.error("Error processing notification event", err);
          channel.nack(msg, false, false);
        }
      });

      this.logger.log(
        `NotificationHandler listening on queue: ${NOTIFICATION_QUEUE}`,
      );
    } catch (err) {
      this.logger.warn(
        "RabbitMQ not available; notification handler disabled.",
        err,
      );
    }
  }

  private async handleMessage(
    routingKey: string,
    payload: unknown,
  ): Promise<void> {
    switch (routingKey) {
      case BookingRoutingKey.CREATED: {
        const data = payload as BookingCreatedPayload;
        await this.notificationService.create({
          userId: data.establishmentId,
          title: "Nova reserva recebida",
          body: `${data.clientName} agendou ${data.serviceName} para ${new Date(data.scheduledAt).toLocaleString("pt-BR")}`,
          type: "BOOKING_CREATED",
        });
        await this.push(
          data.establishmentId,
          "Nova reserva recebida",
          `${data.clientName} agendou ${data.serviceName}`,
        );
        if (data.userEmail) {
          await this.mailService.sendBookingConfirmed(
            data.userEmail,
            data.serviceName,
            "seu pet shop",
            new Date(data.scheduledAt).toLocaleString("pt-BR"),
          );
        }
        break;
      }

      case BookingRoutingKey.STATUS_UPDATED: {
        const data = payload as BookingStatusUpdatedPayload;
        const isConfirmed = data.status === "CONFIRMADO";
        const label = isConfirmed ? "confirmada" : "recusada";
        const type = isConfirmed ? "BOOKING_CONFIRMED" : "BOOKING_REJECTED";
        await this.notificationService.create({
          userId: data.userId,
          title: `Reserva ${label}`,
          body: `Sua reserva em ${data.establishmentName} foi ${label}.`,
          type,
        });
        await this.push(
          data.userId,
          `Reserva ${label}`,
          `Sua reserva em ${data.establishmentName} foi ${label}.`,
        );
        break;
      }

      case BookingRoutingKey.CANCELED: {
        const data = payload as BookingCanceledPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Agendamento cancelado",
          body: `Seu agendamento de ${data.serviceName} em ${data.establishmentName} foi cancelado.`,
          type: "BOOKING_CANCELLED",
        });
        await this.push(
          data.userId,
          "Agendamento cancelado",
          `${data.serviceName} em ${data.establishmentName} foi cancelado.`,
        );
        break;
      }

      case BookingRoutingKey.COMPLETED: {
        const data = payload as BookingCompletedPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Atendimento concluído",
          body: `Seu atendimento de ${data.serviceName} em ${data.establishmentName} foi concluído. Deixe uma avaliação!`,
          type: "BOOKING_COMPLETED",
        });
        await this.push(
          data.userId,
          "Atendimento concluído",
          `${data.serviceName} concluído. Avalie o estabelecimento!`,
        );
        break;
      }

      case BookingRoutingKey.REMINDER: {
        const data = payload as BookingReminderPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Lembrete de agendamento",
          body: `Seu agendamento de ${data.serviceName} em ${data.establishmentName} é amanhã.`,
          type: "BOOKING_REMINDER",
        });
        await this.push(
          data.userId,
          "Lembrete de agendamento ⏰",
          `${data.serviceName} em ${data.establishmentName} é amanhã!`,
        );
        break;
      }

      case MarketplaceRoutingKey.ORDER_CREATED: {
        const data = payload as OrderCreatedPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Pedido realizado",
          body: `Seu pedido de ${data.itemCount} item(s) no valor de R$ ${data.total.toFixed(2)} foi registrado.`,
          type: "ORDER_CREATED",
        });
        await this.push(
          data.userId,
          "Pedido realizado 🛍️",
          `${data.itemCount} item(s) — R$ ${data.total.toFixed(2)}`,
        );
        if (data.userEmail) {
          await this.mailService.sendOrderPlaced(
            data.userEmail,
            data.orderId,
            data.total,
            data.itemCount,
          );
        }
        break;
      }

      case ReviewRoutingKey.CREATED: {
        const data = payload as ReviewCreatedPayload;
        await this.notificationService.create({
          userId: data.establishmentId,
          title: "Nova avaliação recebida",
          body: `Você recebeu uma nova avaliação com ${data.rating} estrela(s).`,
          type: "REVIEW_RECEIVED",
        });
        await this.push(
          data.establishmentId,
          "Nova avaliação ⭐",
          `${data.rating} estrela(s) recebida(s).`,
        );
        break;
      }

      case UserAuthRoutingKey.USER_CREATED: {
        const data = payload as UserCreatedPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Bem-vindo ao MyPet! 🐾",
          body: `Olá, ${data.name}! Sua conta foi criada com sucesso.`,
          type: "AUTH_WELCOME",
        });
        await this.mailService.sendWelcome(data.email, data.name);
        break;
      }

      default:
        this.logger.warn(`Unknown routing key: ${routingKey}`);
    }
  }

  private async push(
    userId: string,
    title: string,
    body: string,
  ): Promise<void> {
    try {
      const token = await this.deviceTokenRepo.findTokenByUserId(userId);
      if (token) {
        await this.fcmService.sendPush(token, title, body);
      }
    } catch (err) {
      this.logger.warn(`Push lookup failed for userId ${userId}: ${err}`);
    }
  }
}
