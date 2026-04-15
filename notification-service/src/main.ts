import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
  app.enableCors({ origin: '*' });
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.RMQ,
    options: {
      urls: [process.env.RABBITMQ_URL ?? 'amqp://mypet:mypet123@localhost:5672'],
      queue: 'mypet_events',
      queueOptions: { durable: true },
      noAck: false,
    },
  });
  await app.startAllMicroservices();
  await app.listen(process.env.PORT ?? 3006);
}
bootstrap();
