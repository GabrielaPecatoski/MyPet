import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from "@nestjs/common";
import { ConfigService } from "@nestjs/config";
import type { Channel, ChannelModel } from "amqplib";
import amqplib from "amqplib";

@Injectable()
export class RabbitMQService implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(RabbitMQService.name);
  private connection?: ChannelModel;
  private channel?: Channel;

  constructor(private readonly configService: ConfigService) {}

  async onModuleInit(): Promise<void> {
    const url = this.configService.get<string>("RABBITMQ_URL");

    if (!url) {
      this.logger.warn("RABBITMQ_URL not configured; RabbitMQ client disabled.");
      return;
    }

    this.connection = await amqplib.connect(url);
    this.channel = await this.connection.createChannel();
    this.logger.log("RabbitMQ connection established");
  }

  async onModuleDestroy(): Promise<void> {
    await this.channel?.close();
    await this.connection?.close();
  }

  getChannel(): Channel {
    if (!this.channel) {
      throw new Error("RabbitMQ channel not initialized");
    }
    return this.channel;
  }

  async createChannel(): Promise<Channel> {
    if (!this.connection) {
      throw new Error("RabbitMQ connection not initialized");
    }
    return this.connection.createChannel();
  }
}
