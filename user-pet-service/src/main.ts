import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.useGlobalPipes(new ValidationPipe({ whitelist: true }));
  app.enableCors({ origin: '*' });
  await app.listen(process.env.PORT ?? 3002);
  console.log('User-Pet Service rodando na porta', process.env.PORT ?? 3002);
}
bootstrap();
