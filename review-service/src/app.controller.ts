import {
  Controller,
  Get,
  Post,
  Param,
  Body,
  Headers,
  UnauthorizedException,
} from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('reviews/establishment/:id')
  getByEstablishment(@Param('id') id: string) {
    return this.appService.findByEstablishment(id);
  }

  @Get('reviews/establishment/:id/stats')
  getStats(@Param('id') id: string) {
    return this.appService.getStats(id);
  }

  @Post('reviews/establishment/:id')
  create(
    @Param('id') establishmentId: string,
    @Body() body: { rating: number; comment?: string; userName?: string },
    @Headers('x-user-id') userId: string,
  ) {
    if (!userId) throw new UnauthorizedException('Usuário não identificado');
    return this.appService.create(establishmentId, { userId, ...body });
  }
}
