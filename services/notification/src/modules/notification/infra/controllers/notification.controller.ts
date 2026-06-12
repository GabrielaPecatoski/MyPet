import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
import { NotificationService } from "@notification/application/services/notification.service";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";

@ApiTags("notifications")
@Controller("notifications")
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly notificationService: NotificationService) {}

  @Post()
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Criar notificação" })
  async create(
    @Body() body: { userId: string; title: string; body: string; type: string },
  ) {
    return this.notificationService.create(body);
  }

  @Get("user/:userId")
  @RequirePermissions(Permission.NOTIFICATIONS_READ)
  @ApiOperation({ summary: "Listar notificações do usuário" })
  async listByUser(@Param("userId") userId: string) {
    return this.notificationService.listByUser(userId);
  }

  @Get("user/:userId/unread")
  @RequirePermissions(Permission.NOTIFICATIONS_READ)
  @ApiOperation({ summary: "Contar notificações não lidas" })
  async countUnread(@Param("userId") userId: string) {
    return this.notificationService.countUnread(userId);
  }

  @Patch(":id/read")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.NOTIFICATIONS_WRITE)
  @ApiOperation({ summary: "Marcar notificação como lida" })
  @ApiNoContentResponse({ description: "Notificação marcada como lida" })
  async markAsRead(@Param("id") id: string) {
    return this.notificationService.markAsRead(id);
  }

  @Patch("user/:userId/read-all")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.NOTIFICATIONS_WRITE)
  @ApiOperation({ summary: "Marcar todas as notificações como lidas" })
  @ApiNoContentResponse({
    description: "Todas as notificações marcadas como lidas",
  })
  async markAllAsRead(@Param("userId") userId: string) {
    return this.notificationService.markAllAsRead(userId);
  }
}
