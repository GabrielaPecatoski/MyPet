import { MiddlewareConsumer, Module, NestModule, RequestMethod } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { JwtModule } from "@nestjs/jwt";
import { ThrottlerModule } from "@nestjs/throttler";
import { AuthGuardMiddleware } from "./auth/auth-guard.middleware";
import { AuthController } from "./auth/auth.controller";
import { HealthController } from "./health/health.controller";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    ThrottlerModule.forRoot([
      {
        ttl: parseInt(process.env.THROTTLE_TTL ?? "60000"),
        limit: parseInt(process.env.THROTTLE_LIMIT ?? "100"),
      },
    ]),
    JwtModule.register({
      secret: process.env.JWT_SECRET ?? "mypet_super_secret_change_in_production",
    }),
  ],
  controllers: [AuthController, HealthController],
})
export class AppModule implements NestModule {
  configure(consumer: MiddlewareConsumer) {
    consumer
      .apply(AuthGuardMiddleware)
      .exclude(
        { path: "auth", method: RequestMethod.ALL },
        { path: "auth/*path", method: RequestMethod.ALL },
        { path: "establishments", method: RequestMethod.GET },
        { path: "establishments/*path", method: RequestMethod.GET },
        { path: "availability/*path", method: RequestMethod.GET },
        { path: "marketplace", method: RequestMethod.GET },
        { path: "marketplace/*path", method: RequestMethod.GET },
        { path: "faq", method: RequestMethod.ALL },
        { path: "faq/*path", method: RequestMethod.ALL },
        { path: "health", method: RequestMethod.GET },
      )
      .forRoutes("*path");
  }
}
