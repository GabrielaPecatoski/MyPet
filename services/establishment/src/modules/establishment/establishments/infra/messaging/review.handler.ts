import { EstablishmentService } from "@estab/establishments/application/services/establishment.service";
import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import {
  ReviewExchangeName,
  ReviewRoutingKey,
} from "@shared/contracts/events/review-events.enum";
import { RabbitMQService } from "@shared/infra/messaging/rabbitmq.service";

interface ReviewCreatedPayload {
  reviewId: string;
  establishmentId: string;
  userId: string;
  rating: number;
  newAverage: number;
  newCount: number;
}

const ESTAB_REVIEW_QUEUE = "establishment.review.queue";

@Injectable()
export class EstablishmentReviewHandler implements OnModuleInit {
  private readonly logger = new Logger(EstablishmentReviewHandler.name);

  constructor(
    private readonly rabbitMQService: RabbitMQService,
    private readonly establishmentService: EstablishmentService,
  ) {}

  async onModuleInit(): Promise<void> {
    try {
      const channel = this.rabbitMQService.getChannel();
      await channel.assertQueue(ESTAB_REVIEW_QUEUE, { durable: true });
      await channel.assertExchange(ReviewExchangeName.CREATED, "direct", {
        durable: true,
      });
      await channel.bindQueue(
        ESTAB_REVIEW_QUEUE,
        ReviewExchangeName.CREATED,
        ReviewRoutingKey.CREATED,
      );

      await channel.consume(ESTAB_REVIEW_QUEUE, async (msg) => {
        if (!msg) return;
        try {
          const payload = JSON.parse(
            msg.content.toString(),
          ) as ReviewCreatedPayload;
          await this.establishmentService.updateRating(
            payload.establishmentId,
            payload.newAverage,
            payload.newCount,
          );
          channel.ack(msg);
        } catch (err) {
          this.logger.error("Error processing review.created event", err);
          channel.nack(msg, false, false);
        }
      });

      this.logger.log(
        `EstablishmentReviewHandler listening on queue: ${ESTAB_REVIEW_QUEUE}`,
      );
    } catch (err) {
      this.logger.warn("RabbitMQ not available; review handler disabled.", err);
    }
  }
}
