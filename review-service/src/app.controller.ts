import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Headers,
  HttpCode,
  UnauthorizedException,
  ForbiddenException,
} from '@nestjs/common';
import { AppService } from './app.service';

const ADMIN_SECRET = process.env.ADMIN_SECRET ?? 'mypet_admin_secret';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  // Reviews
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

  @Get('reviews/admin/stats')
  getAdminStats(@Headers('x-admin-secret') secret: string) {
    if (secret !== ADMIN_SECRET) throw new ForbiddenException('Acesso negado');
    return this.appService.getAdminStats();
  }

  // Complaints — admin
  @Get('reviews/admin/complaints')
  getAllComplaints(@Headers('x-admin-secret') secret: string) {
    if (secret !== ADMIN_SECRET) throw new ForbiddenException('Acesso negado');
    return this.appService.findAllComplaints();
  }

  @Patch('reviews/admin/complaints/:id/resolve')
  resolveComplaint(
    @Param('id') id: string,
    @Headers('x-admin-secret') secret: string,
  ) {
    if (secret !== ADMIN_SECRET) throw new ForbiddenException('Acesso negado');
    return this.appService.resolveComplaint(id);
  }

  @Patch('reviews/admin/complaints/:id/reject')
  rejectComplaint(
    @Param('id') id: string,
    @Headers('x-admin-secret') secret: string,
  ) {
    if (secret !== ADMIN_SECRET) throw new ForbiddenException('Acesso negado');
    return this.appService.rejectComplaint(id);
  }

  @Delete('reviews/admin/complaints/:id')
  @HttpCode(200)
  deleteComplaint(
    @Param('id') id: string,
    @Headers('x-admin-secret') secret: string,
  ) {
    if (secret !== ADMIN_SECRET) throw new ForbiddenException('Acesso negado');
    return this.appService.deleteComplaint(id);
  }

  // Complaints — establishment
  @Get('reviews/complaints/establishment/:id')
  getComplaintsByEstab(@Param('id') id: string) {
    return this.appService.findComplaintsByEstab(id);
  }

  @Post('reviews/complaints')
  createComplaint(
    @Body()
    body: {
      establishmentId: string;
      bookingId?: string;
      subject: string;
      description: string;
      category?: string;
    },
    @Headers('x-user-id') userId: string,
    @Headers('x-user-name') userName: string,
  ) {
    if (!userId) throw new UnauthorizedException('Usuário não identificado');
    return this.appService.createComplaint({ userId, userName, ...body });
  }

  @Patch('reviews/complaints/:id/respond')
  respondComplaint(
    @Param('id') id: string,
    @Body() body: { response: string },
  ) {
    return this.appService.respondComplaint(id, body.response);
  }
}
