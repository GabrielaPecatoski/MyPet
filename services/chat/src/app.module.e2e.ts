/**
 * Minimal app module for local E2E testing.
 * No RabbitMQ, no SharedModule. Guards use jsonwebtoken directly.
 */
import {
  CanActivate,
  ExecutionContext,
  Global,
  Injectable,
  Module,
  UnauthorizedException,
} from "@nestjs/common";
import { ConfigModule, ConfigService } from "@nestjs/config";
import { APP_GUARD } from "@nestjs/core";
import { JwtModule } from "@nestjs/jwt";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import type { Request } from "express";
import * as _jwt from "jsonwebtoken";

import { ChatModule } from "./modules/chat/chat.module";

// Resolve CJS default for both tsx/esbuild and plain node
const jwtLib = (_jwt as unknown as { default?: typeof _jwt }).default ?? _jwt;

@Injectable()
class E2EJwtGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<Request & { user: unknown }>();
    const [type, token] = req.headers.authorization?.split(" ") ?? [];
    if (type !== "Bearer" || !token) throw new UnauthorizedException("Missing token");
    const secret = (process.env.JWT_SECRET ?? "").trim();
    try {
      req.user = jwtLib.verify(token, secret) as unknown;
      return true;
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      console.error(`[E2EJwtGuard] JWT verify failed — secret length=${secret.length} err=${msg}`);
      throw new UnauthorizedException("Invalid token");
    }
  }
}

@Injectable()
class E2EPermissionsGuard implements CanActivate {
  canActivate(): boolean {
    return true;
  }
}

@Global()
@Module({
  providers: [DrizzleService],
  exports: [DrizzleService],
})
class DrizzleModule {}

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true, ignoreEnvFile: true }),
    JwtModule.registerAsync({
      global: true,
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (cfg: ConfigService) => ({
        secret: (cfg.get<string>("JWT_SECRET") ?? "").trim(),
        signOptions: { expiresIn: "7d" },
      }),
    }),
    DrizzleModule,
    ChatModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: E2EJwtGuard },
    { provide: APP_GUARD, useClass: E2EPermissionsGuard },
  ],
})
export class AppModuleE2E {}
