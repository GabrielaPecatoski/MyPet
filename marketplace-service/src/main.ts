import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.enableCors({ origin: '*', methods: ['GET', 'POST', 'PATCH', 'PUT', 'DELETE', 'OPTIONS'] });
  await app.listen(process.env.PORT ?? 3004);
}
bootstrap().catch((err) => {
  console.error('Falha ao iniciar marketplace-service:', err);
  process.exit(1);
});
