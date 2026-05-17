import { ValidationPipe, type Type } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import { DocumentBuilder, SwaggerModule } from "@nestjs/swagger";

type BootstrapHttpAppOptions = {
  title: string;
  description: string;
  version?: string;
  globalPrefix?: string;
  port?: number | string;
};

export async function bootstrapHttpApp(
  rootModule: Type<unknown>,
  options: BootstrapHttpAppOptions,
): Promise<void> {
  const app = await NestFactory.create(rootModule);

  app.enableCors({ origin: "*" });
  app.setGlobalPrefix(options.globalPrefix ?? "v1");
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
    }),
  );

  const documentConfig = new DocumentBuilder()
    .setTitle(options.title)
    .setDescription(options.description)
    .setVersion(options.version ?? "1.0.0")
    .addBearerAuth({ type: "http", scheme: "bearer", bearerFormat: "JWT" })
    .build();

  const document = SwaggerModule.createDocument(app, documentConfig);
  SwaggerModule.setup("docs", app, document);

  await app.listen(options.port ?? process.env.PORT ?? 3000);
}
