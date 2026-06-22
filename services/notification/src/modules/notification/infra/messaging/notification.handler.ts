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
  EmergencyExchangeName,
  EmergencyRoutingKey,
} from "@shared/contracts/events/emergency-events.enum";
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
  establishmentName: string;
  clientName: string;
  userEmail?: string;
  serviceName: string;
  scheduledAt: string;
}

interface BookingStatusUpdatedPayload {
  bookingId: string;
  userId: string;
  userEmail?: string;
  status: string;
  establishmentName: string;
  serviceName?: string;
  scheduledAt?: string;
}

interface BookingCanceledPayload {
  bookingId: string;
  userId: string;
  userEmail?: string;
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
  userEmail?: string;
  serviceName: string;
  establishmentName: string;
  scheduledAt: string;
}

interface BookingTodayReminderPayload {
  bookingId: string;
  establishmentId?: string;
  userId: string;
  clientName: string;
  establishmentName: string;
  serviceName: string;
  scheduledAt: string;
}

interface BookingPhotosAddedPayload {
  bookingId: string;
  userId: string;
  establishmentName: string;
  serviceName: string;
  photoCount: number;
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

interface EmergencyVetCallPayload {
  callId: string;
  vetId: string;
  vetName: string;
  callerName: string;
  callerPhone: string;
  petDescription: string | null;
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
        { exchange: BookingExchangeName.CREATED, routingKey: BookingRoutingKey.CREATED },
        { exchange: BookingExchangeName.STATUS_UPDATED, routingKey: BookingRoutingKey.STATUS_UPDATED },
        { exchange: BookingExchangeName.COMPLETED, routingKey: BookingRoutingKey.COMPLETED },
        { exchange: BookingExchangeName.CANCELED, routingKey: BookingRoutingKey.CANCELED },
        { exchange: BookingExchangeName.REMINDER, routingKey: BookingRoutingKey.REMINDER },
        { exchange: BookingExchangeName.TODAY_REMINDER, routingKey: BookingRoutingKey.TODAY_REMINDER },
        { exchange: BookingExchangeName.PHOTOS_ADDED, routingKey: BookingRoutingKey.PHOTOS_ADDED },
        { exchange: MarketplaceExchangeName.ORDER_CREATED, routingKey: MarketplaceRoutingKey.ORDER_CREATED },
        { exchange: ReviewExchangeName.CREATED, routingKey: ReviewRoutingKey.CREATED },
        { exchange: UserAuthExchangeName.USER_CREATED, routingKey: UserAuthRoutingKey.USER_CREATED },
        { exchange: EmergencyExchangeName.VET_CALL, routingKey: EmergencyRoutingKey.VET_CALL },
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
          await this.mailService.sendBookingReceived(
            data.userEmail,
            data.serviceName,
            data.establishmentName,
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
        if (data.userEmail && data.serviceName) {
          if (isConfirmed && data.scheduledAt) {
            await this.mailService.sendBookingConfirmed(
              data.userEmail,
              data.serviceName,
              data.establishmentName,
              new Date(data.scheduledAt).toLocaleString("pt-BR"),
            );
          } else if (!isConfirmed) {
            await this.mailService.sendBookingCancelled(
              data.userEmail,
              data.serviceName,
              data.establishmentName,
            );
          }
        }
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
        if (data.userEmail) {
          await this.mailService.sendBookingCancelled(
            data.userEmail,
            data.serviceName,
            data.establishmentName,
          );
        }
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
          "Lembrete de agendamento",
          `${data.serviceName} em ${data.establishmentName} é amanhã!`,
        );
        break;
      }

      case BookingRoutingKey.TODAY_REMINDER: {
        const data = payload as BookingTodayReminderPayload;
        const when = new Date(data.scheduledAt).toLocaleTimeString("pt-BR", {
          hour: "2-digit",
          minute: "2-digit",
        });
        if (data.establishmentId) {
          await this.notificationService.create({
            userId: data.establishmentId,
            title: "Atendimento hoje",
            body: `${data.clientName} tem ${data.serviceName} agendado para hoje às ${when}.`,
            type: "BOOKING_TODAY_REMINDER",
          });
        }
        await this.notificationService.create({
          userId: data.userId,
          title: "Seu atendimento é hoje",
          body: `Você tem ${data.serviceName} em ${data.establishmentName} hoje às ${when}.`,
          type: "BOOKING_TODAY_REMINDER",
        });
        break;
      }

      case BookingRoutingKey.PHOTOS_ADDED: {
        const data = payload as BookingPhotosAddedPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Fotos do atendimento",
          body: `Você recebeu novas fotos do seu atendimento de ${data.serviceName} em ${data.establishmentName}.`,
          type: "BOOKING_PHOTOS_ADDED",
        });
        await this.push(
          data.userId,
          "Fotos do atendimento",
          `Novas fotos de ${data.serviceName} em ${data.establishmentName}.`,
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
          "Pedido realizado",
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
          "Nova avaliação",
          `${data.rating} estrela(s) recebida(s).`,
        );
        break;
      }

      case UserAuthRoutingKey.USER_CREATED: {
        const data = payload as UserCreatedPayload;
        await this.notificationService.create({
          userId: data.userId,
          title: "Bem-vindo ao MyPet!",
          body: `Olá, ${data.name}! Sua conta foi criada com sucesso.`,
          type: "AUTH_WELCOME",
        });
        await this.mailService.sendWelcome(data.email, data.name);
        break;
      }

      case EmergencyRoutingKey.VET_CALL: {
        const data = payload as EmergencyVetCallPayload;
        const pet = data.petDescription ? ` · ${data.petDescription}` : "";
        await this.notificationService.create({
          userId: data.vetId,
          title: "Chamado de emergência!",
          body: `${data.callerName} (${data.callerPhone}) precisa de atendimento urgente${pet}.`,
          type: "EMERGENCY_VET_CALL",
        });
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
