import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ClientsModule, Transport } from '@nestjs/microservices';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { RABBITMQ_CLIENT } from './constants';

const SERVICE_NAME = 'booking-service';
const SERVICE_PORT = 3005;

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ClientsModule.register([
      {
        name: RABBITMQ_CLIENT,
        transport: Transport.RMQ,
        options: {
          urls: [process.env.RABBITMQ_URL ?? 'amqp://mypet:mypet123@localhost:5672'],
          queue: 'mypet_events',
          queueOptions: { durable: true },
        },
      },
    ]),
  ],
  controllers: [AppController, HealthController],
  providers: [
    AppService,
    {
      provide: ConsulService,
      useValue: new ConsulService({ serviceName: 'booking-service', servicePort: 3005 }),
    },
  ],
})
export class AppModule {}