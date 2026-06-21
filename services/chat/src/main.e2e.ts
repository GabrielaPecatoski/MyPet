import { Logger, ValidationPipe } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { IoAdapter } from "@nestjs/platform-socket.io";
import { AppModuleE2E } from "./app.module.e2e";

async function bootstrap() {
  const logger = new Logger("E2E-Bootstrap");
  const app = await NestFactory.create(AppModuleE2E);

  app.enableCors({ origin: "*" });
  app.setGlobalPrefix("v1");
  app.useGlobalPipes(new ValidationPipe({ whitelist: true, transform: true }));
  app.useWebSocketAdapter(new IoAdapter(app));

  const port = process.env.PORT ?? 3009;
  await app.listen(port);
  logger.log(`Chat Service (E2E mode) on port ${port}`);
}
bootstrap();
