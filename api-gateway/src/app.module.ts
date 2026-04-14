import { Module, MiddlewareConsumer, NestModule, RequestMethod } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { JwtModule } from '@nestjs/jwt';
import { ProxyMiddleware } from './proxy/proxy.middleware';
import { AuthGuardMiddleware } from './auth/auth-guard.middleware';
import { HealthController } from './health/health.controller';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.THROTTLE_TTL ?? '60000'),
        limit: parseInt(process.env.THROTTLE_LIMIT ?? '100'),
      },
    ]),
    JwtModule.register({
      secret: process.env.JWT_SECRET ?? 'mypet_super_secret_change_in_production',
    }),
  ],
  controllers: [HealthController],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    // Rotas que NÃO precisam de token JWT
    consumer
      .apply(AuthGuardMiddleware)
      .exclude(
        { path: 'auth/login',    method: RequestMethod.POST },
        { path: 'auth/register', method: RequestMethod.POST },
        { path: 'auth/refresh',  method: RequestMethod.POST },
        { path: 'auth/password-recovery/forgot-password', method: RequestMethod.POST },
        { path: 'auth/password-recovery/verify-token', method: RequestMethod.POST },
        { path: 'auth/password-recovery/reset-password', method: RequestMethod.POST },
        { path: 'users/register', method: RequestMethod.POST },
        { path: 'establishments/register', method: RequestMethod.POST },
        { path: 'establishments',       method: RequestMethod.GET },
        { path: 'establishments/(.*)', method: RequestMethod.GET },
        { path: 'marketplace',          method: RequestMethod.GET },
        { path: 'marketplace/(.*)',     method: RequestMethod.GET },
        { path: 'health',               method: RequestMethod.GET },
      )
      .forRoutes('*');

    // Proxy: redireciona cada rota ao microserviço correto
    consumer.apply(ProxyMiddleware).forRoutes('*');
  }
}