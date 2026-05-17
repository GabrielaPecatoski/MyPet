import { Injectable, NestMiddleware, UnauthorizedException } from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import type { NextFunction, Request, Response } from "express";

@Injectable()
export class AuthGuardMiddleware implements NestMiddleware {
  constructor(private readonly jwtService: JwtService) {}

  use(req: Request, _res: Response, next: NextFunction) {
    const authHeader = req.headers["authorization"];

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      throw new UnauthorizedException("Token não informado");
    }

    const token = authHeader.split(" ")[1];

    try {
      const payload = this.jwtService.verify(token, {
        secret: process.env.JWT_SECRET ?? "mypet_super_secret_change_in_production",
      });

      req.headers["x-user-id"] = payload.sub ?? payload.userId;
      req.headers["x-user-role"] = payload.role;

      next();
    } catch {
      throw new UnauthorizedException("Token inválido ou expirado");
    }
  }
}
