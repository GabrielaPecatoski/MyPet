import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { Notification } from './entities/notification.entity';
import { NotificationController } from './notification.controller';
import { NotificationService } from './notification.service';
import { NotificationHandler } from './notification.handler';

@Module({
  imports: [
    TypeOrmModule.forFeature([Notification]),
    ClientsModule.register([{
      name: 'RABBITMQ_CLIENT',
      transport: Transport.RMQ,
      options: {
        urls: [process.env.RABBITMQ_URL ?? 'amqp://mypet:mypet123@localhost:5672'],
        queue: 'mypet_events',
        queueOptions: { durable: true },
        noAck: false,
      },
    }]),
  ],
  controllers: [NotificationController, NotificationHandler],
  providers: [NotificationService],
})
export class NotificationModule {}
