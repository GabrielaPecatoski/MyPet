import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { RabbitMQService } from "@shared/infra/messaging/rabbitmq.service";
import { BookingExchangeName, BookingRoutingKey } from "@shared/contracts/events/booking-events.enum";
import { MarketplaceExchangeName, MarketplaceRoutingKey } from "@shared/contracts/events/marketplace-events.enum";
import { EmergencyExchangeName, EmergencyRoutingKey } from "@shared/contracts/events/emergency-events.enum";
import { NotificationService } from "@notification/application/services/notification.service";

interface BookingCreatedPayload {
  bookingId: string;
  establishmentId: string;
  clientName: string;
  serviceName: string;
  scheduledAt: string;
}

interface BookingStatusUpdatedPayload {
  bookingId: string;
  userId: string;
  status: string;
  establishmentName: string;
}

interface BookingCompletedPayload {
  bookingId: string;
  userId: string;
  establishmentName: string;
  serviceName: string;
}

interface OrderCreatedPayload {
  orderId: string;
  userId: string;
  total: number;
  itemCount: number;
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
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      const channel = this.rabbitMQService.getChannel();
      await channel.assertQueue(NOTIFICATION_QUEUE, { durable: true });

      await channel.assertExchange(BookingExchangeName.CREATED, "direct", { durable: true });
      await channel.assertExchange(BookingExchangeName.STATUS_UPDATED, "direct", { durable: true });
      await channel.assertExchange(BookingExchangeName.COMPLETED, "direct", { durable: true });
      await channel.bindQueue(NOTIFICATION_QUEUE, BookingExchangeName.CREATED, BookingRoutingKey.CREATED);
      await channel.bindQueue(NOTIFICATION_QUEUE, BookingExchangeName.STATUS_UPDATED, BookingRoutingKey.STATUS_UPDATED);
      await channel.bindQueue(NOTIFICATION_QUEUE, BookingExchangeName.COMPLETED, BookingRoutingKey.COMPLETED);

      await channel.assertExchange(MarketplaceExchangeName.ORDER_CREATED, "direct", { durable: true });
      await channel.bindQueue(NOTIFICATION_QUEUE, MarketplaceExchangeName.ORDER_CREATED, MarketplaceRoutingKey.ORDER_CREATED);

      await channel.assertExchange(EmergencyExchangeName.VET_CALL, "direct", { durable: true });
      await channel.bindQueue(NOTIFICATION_QUEUE, EmergencyExchangeName.VET_CALL, EmergencyRoutingKey.VET_CALL);

      await channel.consume(NOTIFICATION_QUEUE, async (msg) => {
        if (!msg) return;
        try {
          const routingKey = msg.fields.routingKey;
          const payload = JSON.parse(msg.content.toString());
          await this.handleMessage(routingKey, payload);
          channel.ack(msg);
        } catch (err) {
          this.logger.error("Error processing notification event", err);
          channel.nack(msg, false, false);
        }
      });

      this.logger.log(`NotificationHandler listening on queue: ${NOTIFICATION_QUEUE}`);
    } catch (err) {
      this.logger.warn("RabbitMQ not available; notification handler disabled.", err);
    }
  }

  private async handleMessage(routingKey: string, payload: unknown): Promise<void> {
    switch (routingKey) {
      case BookingRoutingKey.CREATED: {
        const data = payload as BookingCreatedPayload;
        await this.notificationService.create({
          userId: data.establishmentId,
          title: "Nova reserva recebida",
          body: `${data.clientName} agendou ${data.serviceName} para ${new Date(data.scheduledAt).toLocaleString("pt-BR")}`,
          type: "BOOKING_CREATED",
        });
        break;
      }
      case BookingRoutingKey.STATUS_UPDATED: {
        const data = payload as BookingStatusUpdatedPayload;
        const statusLabel = data.status === "CONFIRMADO" ? "confirmada" : "recusada";
        await this.notificationService.create({
          userId: data.userId,
          title: `Reserva ${statusLabel}`,
          body: `Sua reserva em ${data.establishmentName} foi ${statusLabel}.`,
          type: "BOOKING_STATUS_UPDATED",
        });
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
}
