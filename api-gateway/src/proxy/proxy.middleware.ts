import { Injectable, NestMiddleware } from '@nestjs/common';
import { createProxyMiddleware, Options } from 'http-proxy-middleware';
import { Request, Response, NextFunction } from 'express';

// Mapa: prefixo da rota → microserviço de destino
const ROUTES = [
  { prefix: '/auth',           target: process.env.AUTH_SERVICE_URL          ?? 'http://localhost:3001' },
  { prefix: '/users',          target: process.env.USER_PET_SERVICE_URL      ?? 'http://localhost:3002' },
  { prefix: '/pets',           target: process.env.USER_PET_SERVICE_URL      ?? 'http://localhost:3002' },
  { prefix: '/establishments', target: process.env.ESTABLISHMENT_SERVICE_URL ?? 'http://localhost:3003' },
  { prefix: '/marketplace',    target: process.env.MARKETPLACE_SERVICE_URL   ?? 'http://localhost:3004' },
  { prefix: '/bookings',       target: process.env.BOOKING_SERVICE_URL       ?? 'http://localhost:3005' },
  { prefix: '/notifications',  target: process.env.NOTIFICATION_SERVICE_URL  ?? 'http://localhost:3006' },
  { prefix: '/reviews',        target: process.env.REVIEW_SERVICE_URL        ?? 'http://localhost:3007' },
  { prefix: '/complaints',     target: process.env.REVIEW_SERVICE_URL        ?? 'http://localhost:3007' },
];

@Injectable()
export class ProxyMiddleware implements NestMiddleware {
  private proxies = new Map<string, ReturnType<typeof createProxyMiddleware>>();

  constructor() {
    for (const route of ROUTES) {
      const options: Options = {
        target: route.target,
        changeOrigin: true,
        on: {
          error: (_err, _req, res) => {
            (res as Response).status(502).json({
              statusCode: 502,
              message: `Serviço indisponível: ${route.prefix}`,
            });
          },
        },
      };
      this.proxies.set(route.prefix, createProxyMiddleware(options) as any);
    }
  }

  use(req: Request, res: Response, next: NextFunction) {
    for (const route of ROUTES) {
      if (req.path.startsWith(route.prefix)) {
        const proxy = this.proxies.get(route.prefix);
        if (proxy) return proxy(req, res, next);
      }
    }
    next();
  }
}