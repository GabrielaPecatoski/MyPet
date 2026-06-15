import { Logger } from "@nestjs/common";
import { NestFactory } from "@nestjs/core";
import type { NextFunction, Request, Response } from "express";
import helmet from "helmet";
import { createProxyMiddleware } from "http-proxy-middleware";
import { AppModule } from "./app.module";

const ROUTES = [
  {
    prefix: "/auth",
    target: process.env.AUTH_SERVICE_URL ?? "http://localhost:3001",
  },
  {
    prefix: "/users",
    target: process.env.AUTH_SERVICE_URL ?? "http://localhost:3001",
  },
  {
    prefix: "/pets",
    target: process.env.USER_PET_SERVICE_URL ?? "http://localhost:3002",
  },
  {
    prefix: "/establishments",
    target: process.env.ESTABLISHMENT_SERVICE_URL ?? "http://localhost:3003",
  },
  {
    prefix: "/marketplace",
    target: process.env.MARKETPLACE_SERVICE_URL ?? "http://localhost:3004",
  },
  {
    prefix: "/bookings",
    target: process.env.BOOKING_SERVICE_URL ?? "http://localhost:3005",
  },
  {
    prefix: "/availability",
    target: process.env.BOOKING_SERVICE_URL ?? "http://localhost:3005",
  },
  {
    prefix: "/notifications",
    target: process.env.NOTIFICATION_SERVICE_URL ?? "http://localhost:3006",
  },
  {
    prefix: "/reviews",
    target: process.env.REVIEW_SERVICE_URL ?? "http://localhost:3007",
  },
  {
    prefix: "/faq",
    target: process.env.FAQ_SERVICE_URL ?? "http://localhost:3008",
  },
  {
    prefix: "/drivers",
    target: process.env.DRIVER_SERVICE_URL ?? "http://localhost:3009",
  },
  {
    prefix: "/veterinarians",
    target: process.env.VET_SERVICE_URL ?? "http://localhost:3010",
  },
];

const GATEWAY_HANDLED = ["GET /auth/me", "POST /auth/refresh"];

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Methods": "GET,POST,PATCH,PUT,DELETE,OPTIONS",
  "Access-Control-Allow-Headers": "Content-Type,Authorization",
};

async function bootstrap() {
  const logger = new Logger("Bootstrap");
  const app = await NestFactory.create(AppModule, { bodyParser: false });

  app.use(
    helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }),
  );

  const expressApp = app.getHttpAdapter().getInstance();

  expressApp.use((req: Request, res: Response, next: NextFunction) => {
    if (req.method === "OPTIONS") {
      for (const [k, v] of Object.entries(CORS_HEADERS)) res.setHeader(k, v);
      return res.sendStatus(204);
    }
    next();
  });

  for (const route of ROUTES) {
    expressApp.use(
      route.prefix,
      (req: Request, res: Response, next: NextFunction) => {
        const fullPath = `${route.prefix}${req.path}`;
        if (GATEWAY_HANDLED.includes(`${req.method} ${fullPath}`))
          return next();

        const proxy = createProxyMiddleware({
          target: route.target,
          changeOrigin: true,
          pathRewrite: (path: string) => `/v1${route.prefix}${path}`,
          on: {
            proxyRes: (_proxyRes: unknown, _req: unknown, res: Response) => {
              for (const [k, v] of Object.entries(CORS_HEADERS))
                res.setHeader(k, v);
            },
            error: (_err: unknown, _req: unknown, res: Response) => {
              for (const [k, v] of Object.entries(CORS_HEADERS))
                res.setHeader(k, v);
              res.status(502).json({
                statusCode: 502,
                message: `Serviço indisponível: ${route.prefix}`,
              });
            },
          },
        });
        return proxy(req, res, next);
      },
    );
  }

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  logger.log(`API Gateway rodando na porta ${port}`);
}
bootstrap();
