import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import { createProxyMiddleware } from 'http-proxy-middleware';
import { Request, Response, NextFunction } from 'express';

const ROUTES = [
  { prefix: '/auth',           target: process.env.AUTH_SERVICE_URL          ?? 'http://localhost:3001' },
  { prefix: '/users',          target: process.env.USER_PET_SERVICE_URL      ?? 'http://localhost:3002' },
  { prefix: '/pets',           target: process.env.USER_PET_SERVICE_URL      ?? 'http://localhost:3002' },
  { prefix: '/establishments', target: process.env.ESTABLISHMENT_SERVICE_URL ?? 'http://localhost:3003' },
  { prefix: '/marketplace',    target: process.env.MARKETPLACE_SERVICE_URL   ?? 'http://localhost:3004' },
  { prefix: '/bookings',       target: process.env.BOOKING_SERVICE_URL       ?? 'http://localhost:3005' },
  { prefix: '/availability',   target: process.env.BOOKING_SERVICE_URL       ?? 'http://localhost:3005' },
  { prefix: '/notifications',  target: process.env.NOTIFICATION_SERVICE_URL  ?? 'http://localhost:3006' },
  { prefix: '/reviews',        target: process.env.REVIEW_SERVICE_URL        ?? 'http://localhost:3007' },
];

const GATEWAY_HANDLED = ['/auth/me', '/auth/refresh'];

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PATCH,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));

  const expressApp = app.getHttpAdapter().getInstance();

  expressApp.options('*', (_req: Request, res: Response) => {
    Object.entries(CORS_HEADERS).forEach(([k, v]) => res.setHeader(k, v));
    res.sendStatus(204);
  });

  for (const route of ROUTES) {
    expressApp.use(route.prefix, (req: Request, res: Response, next: NextFunction) => {
      const fullPath = `${route.prefix}${req.path}`;
      if (GATEWAY_HANDLED.includes(fullPath)) return next();

      const proxy = createProxyMiddleware({
        target: route.target,
        changeOrigin: true,
        pathRewrite: (path) => `${route.prefix}${path}`,
        on: {
          proxyRes: (_proxyRes: any, _req: any, res: any) => {
            Object.entries(CORS_HEADERS).forEach(([k, v]) => res.setHeader(k, v));
          },
          error: (_err: any, _req: any, res: any) => {
            Object.entries(CORS_HEADERS).forEach(([k, v]) => res.setHeader(k, v));
            res.status(502).json({ statusCode: 502, message: `Serviço indisponível: ${route.prefix}` });
          },
        },
      });
      return proxy(req, res, next);
    });
  }

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`API Gateway rodando na porta ${port}`);
}
bootstrap();
