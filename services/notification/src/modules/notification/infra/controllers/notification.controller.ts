import {
  Body,
  Controller,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
  Res,
  Sse,
  UnauthorizedException,
} from "@nestjs/common";
import { JwtService } from "@nestjs/jwt";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
import { NotificationService } from "@notification/application/services/notification.service";
import {
  NotificationStreamService,
  StreamEvent,
} from "@notification/application/services/notification-stream.service";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import type { Response } from "express";
import { interval, map, merge, Observable } from "rxjs";

interface SseMessage {
  data: StreamEvent | { type: "ping" };
}

@ApiTags("notifications")
@Controller("notifications")
@ApiBearerAuth()
export class NotificationsController {
  constructor(
    private readonly notificationService: NotificationService,
    private readonly streamService: NotificationStreamService,
    private readonly jwtService: JwtService,
  ) {}

  @Sse("stream/:userId")
  @Public()
  @ApiOperation({ summary: "Stream de notificações em tempo real (SSE)" })
  async stream(
    @Param("userId") userId: string,
    @Query("token") token: string | undefined,
    @Res({ passthrough: true }) res: Response,
  ): Promise<Observable<SseMessage>> {
    if (!token) throw new UnauthorizedException("Missing token");
    try {
      await this.jwtService.verifyAsync(token);
    } catch {
      throw new UnauthorizedException("Invalid or expired token");
    }

    res.setHeader("X-Accel-Buffering", "no");

    const { stream, unsubscribe } = this.streamService.subscribe(userId);
    res.on("close", unsubscribe);

    return merge(
      stream.pipe(map((event): SseMessage => ({ data: event }))),
      interval(25_000).pipe(
        map((): SseMessage => ({ data: { type: "ping" } })),
      ),
    );
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
