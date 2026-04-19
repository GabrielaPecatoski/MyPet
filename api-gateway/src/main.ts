import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import helmet from 'helmet';
import { createProxyMiddleware } from 'http-proxy-middleware';

const ROUTES = [
  { prefix: '/auth',           target: process.env.AUTH_SERVICE_URL          ?? 'http://localhost:3001' },
  { prefix: '/users',          target: process.env.USER_PET_SERVICE_URL      ?? 'http://localhost:3002' },
  { prefix: '/pets',           target: process.env.USER_PET_SERVICE_URL      ?? 'http://localhost:3002' },
  { prefix: '/establishments', target: process.env.ESTABLISHMENT_SERVICE_URL ?? 'http://localhost:3003' },
  { prefix: '/marketplace',    target: process.env.MARKETPLACE_SERVICE_URL   ?? 'http://localhost:3004' },
  { prefix: '/bookings',       target: process.env.BOOKING_SERVICE_URL       ?? 'http://localhost:3005' },
  { prefix: '/notifications',  target: process.env.NOTIFICATION_SERVICE_URL  ?? 'http://localhost:3006' },
  { prefix: '/reviews',        target: process.env.REVIEW_SERVICE_URL        ?? 'http://localhost:3007' },
];

const CORS_HEADERS = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET,POST,PATCH,PUT,DELETE,OPTIONS',
  'Access-Control-Allow-Headers': 'Content-Type,Authorization',
};

async function bootstrap() {
  const app = await NestFactory.create(AppModule);

  app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));

  // Apply proxies directly to the Express instance before NestJS routing
  const expressApp = app.getHttpAdapter().getInstance();

  // Handle preflight OPTIONS for all routes
  expressApp.options('*', (_req: any, res: any) => {
    Object.entries(CORS_HEADERS).forEach(([k, v]) => res.setHeader(k, v));
    res.sendStatus(204);
  });

  for (const route of ROUTES) {
    expressApp.use(
      route.prefix,
      createProxyMiddleware({
        target: route.target,
        changeOrigin: true,
        pathRewrite: { '^/': `${route.prefix}/` },
        on: {
          proxyRes: (_proxyRes: any, _req: any, res: any) => {
            Object.entries(CORS_HEADERS).forEach(([k, v]) => res.setHeader(k, v));
          },
          error: (_err: any, _req: any, res: any) => {
            Object.entries(CORS_HEADERS).forEach(([k, v]) => res.setHeader(k, v));
            res.status(502).json({
              statusCode: 502,
              message: `Serviço indisponível: ${route.prefix}`,
            });
          },
        },
      }),
    );
  }

  const port = process.env.PORT ?? 3000;
  await app.listen(port);
  console.log(`API Gateway rodando na porta ${port}`);
}
bootstrap();
