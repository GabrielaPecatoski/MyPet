import { FaqService } from "@faq/faqs/application/services/faq.service";
import {
  Body, Controller, Delete, Get, HttpCode, HttpStatus,
  Param, Patch, Post, Put, Query,
} from "@nestjs/common";
import { ApiBearerAuth, ApiNoContentResponse, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";

@ApiTags("faq")
@Controller("faq")
export class FaqController {
  constructor(private readonly faqService: FaqService) {}

  @Get()
  @Public()
  @ApiOperation({ summary: "Listar FAQs públicos" })
  async listFaq(@Query("category") category?: string) {
    return this.faqService.listFaq(category);
  }

  @Get("categories")
  @Public()
  @ApiOperation({ summary: "Listar categorias" })
  async getCategories() {
    return this.faqService.getCategories();
  }

  @Get("admin/all")
  @ApiBearerAuth()
  @RequirePermissions(Permission.FAQ_READ)
  @ApiOperation({ summary: "Listar todos os FAQs (admin)" })
  async listAdmin() {
    return this.faqService.listFaqAdmin();
  }

  @Post("admin")
  @ApiBearerAuth()
  @RequirePermissions(Permission.FAQ_WRITE)
  @ApiOperation({ summary: "Criar FAQ (admin)" })
  async createFaq(@Body() body: { question: string; answer: string; category?: string; targetRole?: string; order?: number }) {
    return this.faqService.createFaq(body);
  }

  @Put("admin/:id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.FAQ_WRITE)
  @ApiOperation({ summary: "Atualizar FAQ (admin)" })
  @ApiNoContentResponse({ description: "FAQ atualizado" })
  async updateFaq(@Param("id") id: string, @Body() body: { question?: string; answer?: string; category?: string; targetRole?: string; order?: number }) {
    return this.faqService.updateFaq(id, body);
  }

  @Delete("admin/:id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.FAQ_DELETE)
  @ApiOperation({ summary: "Excluir FAQ (admin)" })
  @ApiNoContentResponse({ description: "FAQ excluído" })
  async deleteFaq(@Param("id") id: string) {
    return this.faqService.deleteFaq(id);
  }

  @Put(":id/view")
  @Public()
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiOperation({ summary: "Incrementar visualizações do FAQ" })
  async incrementView(@Param("id") id: string) {
    return this.faqService.incrementViewCount(id);
  }

  @Post("questions")
  @ApiBearerAuth()
  @RequirePermissions(Permission.QUESTIONS_WRITE)
  @ApiOperation({ summary: "Enviar pergunta" })
  async submitQuestion(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { question: string },
  ) {
    return this.faqService.submitQuestion(user.sub, { question: body.question, userName: user.email, userRole: user.role });
  }

  @Get("questions/user/:userId")
  @ApiBearerAuth()
  @RequirePermissions(Permission.QUESTIONS_READ)
  @ApiOperation({ summary: "Listar perguntas do usuário" })
  async listUserQuestions(@Param("userId") userId: string) {
    return this.faqService.listUserQuestions(userId);
  }

  @Get("questions/admin/all")
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_READ)
  @ApiOperation({ summary: "Listar todas as perguntas (admin)" })
  async listAllQuestions(@Query("status") status?: string) {
    return this.faqService.listQuestions(status);
  }

  @Put("questions/admin/:id/answer")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Responder pergunta (admin)" })
  @ApiNoContentResponse({ description: "Resposta enviada" })
  async answerQuestion(@Param("id") id: string, @Body() body: { answer: string }) {
    return this.faqService.answerQuestion(id, body.answer);
  }

  @Put("questions/admin/:id/close")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Fechar pergunta (admin)" })
  @ApiNoContentResponse({ description: "Pergunta fechada" })
  async closeQuestion(@Param("id") id: string) {
    return this.faqService.closeQuestion(id);
  }
}
