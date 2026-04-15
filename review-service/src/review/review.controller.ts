import {
  Controller, Get, Post, Delete, Patch,
  Param, Body, HttpCode, Headers, Query,
} from '@nestjs/common';
import { ReviewService } from './review.service';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateComplaintDto } from './dto/create-complaint.dto';
import { UpdateComplaintStatusDto } from './dto/update-complaint-status.dto';

@Controller()
export class ReviewController {
  constructor(private readonly reviewService: ReviewService) {}

  @Get('reviews')
  findAll() {
    return this.reviewService.findAll();
  }

  @Get('reviews/establishment/:id')
  findByEstablishment(@Param('id') id: string) {
    return this.reviewService.findByEstablishment(id);
  }

  @Get('reviews/average/:establishmentId')
  averageRating(@Param('establishmentId') id: string) {
    return this.reviewService.averageRating(id);
  }

  @Get('reviews/user/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.reviewService.findByUser(userId);
  }

  @Post('reviews')
  createReview(@Body() dto: CreateReviewDto) {
    return this.reviewService.createReview(dto);
  }

  @Delete('reviews/:id')
  @HttpCode(204)
  deleteReview(
    @Param('id') id: string,
    @Headers('x-user-id') userId: string,
    @Headers('x-user-role') role: string,
  ) {
    return this.reviewService.deleteReview(id, userId, role === 'ADMIN');
  }

  @Get('complaints')
  findAllComplaints(
    @Query('userId') userId?: string,
    @Query('establishmentId') establishmentId?: string,
  ) {
    return this.reviewService.findAllComplaints(userId, establishmentId);
  }

  @Get('complaints/:id')
  findComplaintById(@Param('id') id: string) {
    return this.reviewService.findComplaintById(id);
  }

  @Post('complaints')
  createComplaint(@Body() dto: CreateComplaintDto) {
    return this.reviewService.createComplaint(dto);
  }

  @Patch('complaints/:id/respond')
  respondComplaint(
    @Param('id') id: string,
    @Body() body: { response: string },
  ) {
    return this.reviewService.respondComplaint(id, body.response);
  }

  @Patch('complaints/:id/resolve')
  resolveComplaint(
    @Param('id') id: string,
    @Body() body: { moderatorNote?: string },
  ) {
    return this.reviewService.resolveComplaint(id, body?.moderatorNote);
  }

  @Patch('complaints/:id/archive')
  archiveComplaint(@Param('id') id: string) {
    return this.reviewService.archiveComplaint(id);
  }

  @Delete('complaints/:id')
  @HttpCode(200)
  removeComplaint(@Param('id') id: string) {
    return this.reviewService.removeComplaint(id);
  }

  @Patch('complaints/:id/status')
  updateComplaintStatus(
    @Param('id') id: string,
    @Body() dto: UpdateComplaintStatusDto,
  ) {
    return this.reviewService.updateComplaintStatus(id, dto.status, dto.moderatorNote);
  }
}
