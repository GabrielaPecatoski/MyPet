import { ReviewService } from "@review/reviews/application/services/review.service";
import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Query } from "@nestjs/common";
import { ApiBearerAuth, ApiNoContentResponse, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";

@ApiTags("reviews")
@Controller("reviews")
export class ReviewsController {
  constructor(private readonly reviewService: ReviewService) {}

  @Get("establishment/:id")
  @Public()
  @ApiOperation({ summary: "Listar avaliações do estabelecimento" })
  async getReviews(@Param("id") id: string) {
    return this.reviewService.getReviews(id);
  }

  @Get("establishment/:id/stats")
  @Public()
  @ApiOperation({ summary: "Estatísticas de avaliações" })
  async getStats(@Param("id") id: string) {
    return this.reviewService.getStats(id);
  }

  @Post("establishment/:id")
  @ApiBearerAuth()
  @RequirePermissions(Permission.REVIEWS_WRITE)
  @ApiOperation({ summary: "Criar avaliação" })
  async createReview(
    @Param("id") establishmentId: string,
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { rating: number; comment?: string },
  ) {
    return this.reviewService.createReview(user.sub, {
      establishmentId,
      userName: user.email,
      rating: body.rating,
      comment: body.comment,
    });
  }

  @Get("admin/stats")
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_READ)
  @ApiOperation({ summary: "Estatísticas globais de avaliações (admin)" })
  async getAdminStats() {
    return this.reviewService.getAdminStats();
  }

  @Get("admin/complaints")
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_READ)
  @ApiOperation({ summary: "Listar reclamações (admin)" })
  async getComplaints(@Query("status") status?: string) {
    return this.reviewService.getComplaints(status);
  }

  @Patch("admin/complaints/:id/resolve")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Resolver reclamação (admin)" })
  @ApiNoContentResponse({ description: "Reclamação resolvida" })
  async resolve(@Param("id") id: string) {
    return this.reviewService.resolveComplaint(id);
  }

  @Patch("admin/complaints/:id/reject")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Rejeitar reclamação (admin)" })
  @ApiNoContentResponse({ description: "Reclamação rejeitada" })
  async reject(@Param("id") id: string) {
    return this.reviewService.rejectComplaint(id);
  }

  @Delete("admin/complaints/:id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Excluir reclamação (admin)" })
  @ApiNoContentResponse({ description: "Reclamação excluída" })
  async deleteComplaint(@Param("id") id: string) {
    return this.reviewService.deleteComplaint(id);
  }

  @Get("complaints/establishment/:id")
  @ApiBearerAuth()
  @RequirePermissions(Permission.COMPLAINTS_READ)
  @ApiOperation({ summary: "Listar reclamações do estabelecimento" })
  async getEstablishmentComplaints(@Param("id") id: string) {
    return this.reviewService.getComplaintsByEstablishment(id);
  }

  @Post("complaints")
  @ApiBearerAuth()
  @RequirePermissions(Permission.COMPLAINTS_WRITE)
  @ApiOperation({ summary: "Criar reclamação" })
  async createComplaint(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: { establishmentId: string; bookingId?: string; subject: string; description: string; category?: string },
  ) {
    return this.reviewService.createComplaint(user.sub, user.email, body);
  }

  @Patch("complaints/:id/respond")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.COMPLAINTS_WRITE)
  @ApiOperation({ summary: "Responder reclamação" })
  @ApiNoContentResponse({ description: "Resposta enviada" })
  async respond(
    @Param("id") id: string,
    @Body() body: { response: string },
  ) {
    return this.reviewService.respondToComplaint(id, body.response);
  }
}
