// @ts-ignore
import { Controller, Post, Body, HttpCode, HttpStatus } from '@nestjs/common';
// @ts-ignore
import { PasswordRecoveryService } from '../password-recovery/password-recovery.service';
// @ts-ignore
import { LoginDto } from './auth.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly passwordRecoveryService: PasswordRecoveryService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  async login(@Body() loginDto: LoginDto) {
    return await this.passwordRecoveryService.login(loginDto.email, loginDto.password);
  }
}
