import {
  Controller,
  Get,
  Post,
  Req,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Request } from 'express';

@Controller('auth')
export class AuthController {
  constructor(private readonly jwtService: JwtService) {}

  @Get('me')
  me(@Req() req: Request) {
    const auth = req.headers['authorization'];
    if (!auth?.startsWith('Bearer ')) throw new UnauthorizedException('Token não informado');

    try {
      const payload = this.jwtService.verify(auth.split(' ')[1], {
        secret: process.env.JWT_SECRET ?? 'mypet_super_secret_change_in_production',
      });
      return {
        id: payload.sub,
        name: payload.name,
        email: payload.email,
        role: payload.role,
      };
    } catch {
      throw new UnauthorizedException('Token inválido ou expirado');
    }
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(@Req() req: Request) {
    const auth = req.headers['authorization'];
    if (!auth?.startsWith('Bearer ')) throw new UnauthorizedException('Token não informado');

    try {
      const payload = this.jwtService.verify(auth.split(' ')[1], {
        secret: process.env.JWT_SECRET ?? 'mypet_super_secret_change_in_production',
      });
      const newToken = this.jwtService.sign(
        { sub: payload.sub, email: payload.email, name: payload.name, role: payload.role },
        { secret: process.env.JWT_SECRET ?? 'mypet_super_secret_change_in_production', expiresIn: '7d' },
      );
      return {
        access_token: newToken,
        user: { id: payload.sub, name: payload.name, email: payload.email, role: payload.role },
      };
    } catch {
      throw new UnauthorizedException('Token inválido ou expirado');
    }
  }
}
