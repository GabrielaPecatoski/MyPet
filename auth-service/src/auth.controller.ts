import {
  Controller,
  Get,
  Post,
  Delete,
  Body,
  Headers,
  Param,
  HttpCode,
  HttpStatus,
  UnauthorizedException,
} from '@nestjs/common';
import { AuthService } from './auth.service';
import { LoginDto, RegisterDto } from './login.dto';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('login')
  @HttpCode(HttpStatus.OK)
  login(@Body() dto: LoginDto) {
    return this.authService.login(dto);
  }

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  register(@Body() dto: RegisterDto) {
    return this.authService.register(dto);
  }

  @Get('me')
  me(
    @Headers('authorization') auth: string,
    @Headers('x-user-id') xUserId: string,
  ) {
    const userId = xUserId || this.authService.extractUserId(auth);
    if (!userId) throw new UnauthorizedException('Token não informado');
    return this.authService.me(userId);
  }

  @Post('refresh')
  @HttpCode(HttpStatus.OK)
  refresh(
    @Headers('authorization') auth: string,
    @Headers('x-user-id') xUserId: string,
  ) {
    const userId = xUserId || this.authService.extractUserId(auth);
    if (!userId) throw new UnauthorizedException('Token não informado');
    return this.authService.refresh(userId);
  }

  @Get('admin/users')
  getAllUsers() {
    return this.authService.getAllUsers();
  }

  @Delete('admin/users/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  deleteUser(@Param('id') id: string) {
    return this.authService.deleteUser(id);
  }
}
