import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  MessageEvent,
  Param,
  Patch,
  Post,
  Sse,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
import { NotificationService } from "@notification/application/services/notification.service";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import { Observable } from "rxjs";

@ApiTags("notifications")
@Controller("notifications")
@ApiBearerAuth()
export class NotificationsController {
  constructor(private readonly notificationService: NotificationService) {}

  @Get("health")
  @Public()
  @ApiOperation({ summary: "Health check" })
  health() {
    return { status: "ok", service: "notification-service" };
  }

  @Sse("stream/:userId")
  @Public()
  @ApiOperation({ summary: "SSE stream de notificações em tempo real" })
  stream(@Param("userId") userId: string): Observable<MessageEvent> {
    return this.notificationService.getStream(userId) as Observable<MessageEvent>;
  }

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
  @RequirePermissions(Permission.NOTIFICATIONS_WRITE)
  @ApiOperation({ summary: "Marcar notificação como lida" })
  @ApiOkResponse({ description: "Notificação marcada como lida" })
  async markAsRead(@Param("id") id: string) {
    return this.notificationService.markAsRead(id);
  }

  @Patch("user/:userId/read-all")
  @RequirePermissions(Permission.NOTIFICATIONS_WRITE)
  @ApiOperation({ summary: "Marcar todas as notificações como lidas" })
  @ApiOkResponse({ description: "Todas as notificações marcadas como lidas" })
  async markAllAsRead(@Param("userId") userId: string) {
    return this.notificationService.markAllAsRead(userId);
  }

  @Post("device-token")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.NOTIFICATIONS_WRITE)
  @ApiOperation({ summary: "Registrar device token FCM" })
  @ApiNoContentResponse({ description: "Token registrado" })
  async registerDeviceToken(
    @Body() body: { userId: string; token: string; platform?: string },
  ) {
    await this.notificationService.saveDeviceToken(
      body.userId,
      body.token,
      body.platform ?? "android",
    );
  }

  @Delete("device-token/:userId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.NOTIFICATIONS_WRITE)
  @ApiOperation({ summary: "Remover device token FCM" })
  @ApiNoContentResponse({ description: "Token removido" })
  async removeDeviceToken(@Param("userId") userId: string) {
    await this.notificationService.removeDeviceToken(userId);
  }
}
