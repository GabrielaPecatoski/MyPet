import { NestFactory } from '@nestjs/core';
import { MicroserviceOptions, Transport } from '@nestjs/microservices';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  // HTTP server sobe primeiro (independente do RabbitMQ)
  await app.listen(process.env.PORT ?? 3006);
  console.log('Notification Service HTTP rodando na porta 3006');

  // RabbitMQ é opcional — não derruba o serviço se indisponível
  app.connectMicroservice<MicroserviceOptions>({
    transport: Transport.RMQ,
    options: {
      urls: [
        process.env.RABBITMQ_URL ?? 'amqp://mypet:mypet123@localhost:5672',
      ],
      queue: 'mypet_events',
      queueOptions: { durable: true },
      noAck: false,
    },
  });

  app.startAllMicroservices().catch((err: Error) => {
    console.warn(
      'RabbitMQ indisponível — notificações desativadas:',
      err.message,
    );
  });
}
void bootstrap();
