import {
  Controller, Get, Post, Patch, Delete,
  Param, Body, HttpCode,
} from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('reviews/establishment/:estabId')
  getByEstablishment(@Param('estabId') estabId: string) {
    return this.appService.getByEstablishment(estabId);
  }

  @Post('reviews')
  createReview(@Body() body: any) {
    return this.appService.createReview(body);
  }

  @Get('reviews/admin/complaints')
  getAllComplaints() {
    return this.appService.getAllComplaints();
  }

  @Patch('reviews/admin/complaints/:id/resolve')
  resolveComplaint(@Param('id') id: string) {
    return this.appService.resolveComplaint(id);
  }

  @Delete('reviews/admin/complaints/:id')
  @HttpCode(204)
  deleteComplaint(@Param('id') id: string) {
    return this.appService.deleteComplaint(id);
  }

  @Get('reviews/complaints/establishment/:estabId')
  getComplaintsByEstab(@Param('estabId') estabId: string) {
    return this.appService.getComplaintsByEstab(estabId);
  }

  @Post('reviews/complaints')
  createComplaint(@Body() body: any) {
    return this.appService.createComplaint(body);
  }

  @Patch('reviews/complaints/:id/respond')
  respondComplaint(@Param('id') id: string, @Body() body: { response: string }) {
    return this.appService.respondComplaint(id, body.response);
  }
}
