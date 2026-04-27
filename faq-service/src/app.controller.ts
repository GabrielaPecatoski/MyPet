import {
  Controller,
  Get,
  Post,
  Put,
  Delete,
  Param,
  Body,
  Query,
  Headers,
  ForbiddenException,
  NotFoundException,
} from '@nestjs/common';
import { AppService } from './app.service.js';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  // ── FAQ Items (público) ───────────────────────────────────────────

  @Get('faq')
  getActiveFaqs(@Query('category') category?: string) {
    return this.appService.findActiveFaqs(category);
  }

  @Get('faq/categories')
  getCategories() {
    return this.appService.getCategories();
  }

  // ── FAQ Items (admin) ─────────────────────────────────────────────

  @Get('faq/admin/all')
  getAllFaqs(@Headers('x-admin-secret') secret: string) {
    this.checkAdmin(secret);
    return this.appService.findAllFaqs();
  }

  @Post('faq/admin')
  createFaq(
    @Headers('x-admin-secret') secret: string,
    @Body()
    body: {
      question: string;
      answer: string;
      category?: string;
      order?: number;
    },
  ) {
    this.checkAdmin(secret);
    return this.appService.createFaq(body);
  }

  @Put('faq/admin/:id')
  updateFaq(
    @Headers('x-admin-secret') secret: string,
    @Param('id') id: string,
    @Body()
    body: {
      question?: string;
      answer?: string;
      category?: string;
      order?: number;
      active?: boolean;
    },
  ) {
    this.checkAdmin(secret);
    return this.appService.updateFaq(id, body);
  }

  @Delete('faq/admin/:id')
  deleteFaq(
    @Headers('x-admin-secret') secret: string,
    @Param('id') id: string,
  ) {
    this.checkAdmin(secret);
    return this.appService.deleteFaq(id);
  }

  // ── Perguntas de usuários ─────────────────────────────────────────

  @Post('faq/questions')
  submitQuestion(
    @Body()
    body: {
      userId: string;
      userName: string;
      userRole: string;
      question: string;
    },
  ) {
    return this.appService.submitQuestion(body);
  }

  @Get('faq/questions/user/:userId')
  getUserQuestions(@Param('userId') userId: string) {
    return this.appService.getUserQuestions(userId);
  }

  // ── Admin: gerenciar perguntas ────────────────────────────────────

  @Get('faq/questions/admin/all')
  getAllQuestions(
    @Headers('x-admin-secret') secret: string,
    @Query('status') status?: string,
  ) {
    this.checkAdmin(secret);
    return this.appService.getAllQuestions(status);
  }

  @Put('faq/questions/admin/:id/answer')
  answerQuestion(
    @Headers('x-admin-secret') secret: string,
    @Param('id') id: string,
    @Body() body: { answer: string },
  ) {
    this.checkAdmin(secret);
    if (!body.answer?.trim()) {
      throw new NotFoundException('Resposta não pode ser vazia');
    }
    return this.appService.answerQuestion(id, body.answer);
  }

  @Put('faq/questions/admin/:id/close')
  closeQuestion(
    @Headers('x-admin-secret') secret: string,
    @Param('id') id: string,
  ) {
    this.checkAdmin(secret);
    return this.appService.closeQuestion(id);
  }

  // ── Util ──────────────────────────────────────────────────────────

  private checkAdmin(secret: string) {
    const expected = process.env.ADMIN_SECRET ?? 'mypet_admin_secret';
    if (secret !== expected) {
      throw new ForbiddenException('Acesso negado');
    }
  }
}
