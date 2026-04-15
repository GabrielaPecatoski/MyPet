import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { BookingModule } from './booking/booking.module';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { Booking } from './booking/entities/booking.entity';

export const RABBITMQ_CLIENT = 'RABBITMQ_CLIENT';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [Booking],
      synchronize: true,
      ssl: false,
    }),
    ClientsModule.register([{
      name: RABBITMQ_CLIENT,
      transport: Transport.RMQ,
      options: {
        urls: [process.env.RABBITMQ_URL ?? 'amqp://mypet:mypet123@localhost:5672'],
        queue: 'mypet_events',
        queueOptions: { durable: true },
      },
    }]),
    BookingModule,
  ],
  controllers: [HealthController],
  providers: [{
    provide: ConsulService,
    useValue: new ConsulService({ serviceName: 'booking-service', servicePort: 3005 }),
  }],
})
export class AppModule {}
