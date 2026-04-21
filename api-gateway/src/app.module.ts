import { Module, MiddlewareConsumer, NestModule, RequestMethod } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { ThrottlerModule } from '@nestjs/throttler';
import { JwtModule } from '@nestjs/jwt';
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
        { path: 'auth(.*)', method: RequestMethod.ALL },
        { path: 'establishments',       method: RequestMethod.GET },
        { path: 'establishments/(.*)', method: RequestMethod.GET },
        { path: 'marketplace',          method: RequestMethod.GET },
        { path: 'marketplace/(.*)',     method: RequestMethod.GET },
        { path: 'health',               method: RequestMethod.GET },
      )
      .forRoutes('*');
  }
}