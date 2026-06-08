import {
  Body,
  Controller,
  DefaultValuePipe,
  Get,
  Param,
  ParseIntPipe,
  Post,
  Query,
} from "@nestjs/common";
import { ApiBearerAuth, ApiOkResponse, ApiTags } from "@nestjs/swagger";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";
import { Permission } from "@shared/domain/enums/permission.enum";
import { CreateConversationDto } from "../../application/dtos/create-conversation.dto";
import { ChatService } from "../../application/services/chat.service";
import { Conversation } from "../../domain/models/conversation.entity";
import { Message } from "../../domain/models/message.entity";

function toConversationDto(c: Conversation) {
  return {
    id: c.id,
    bookingId: c.bookingId,
    clientId: c.clientId,
    establishmentId: c.establishmentId,
    lastMessageAt: c.lastMessageAt,
    createdAt: c.createdAt,
  };
}

function toMessageDto(m: Message) {
  return {
    id: m.id,
    conversationId: m.conversationId,
    senderId: m.senderId,
    senderRole: m.senderRole,
    content: m.content,
    readAt: m.readAt,
    createdAt: m.createdAt,
  };
}

@ApiTags("conversations")
@ApiBearerAuth()
@Controller("conversations")
export class ChatController {
  constructor(private readonly chatService: ChatService) {}

  @Post()
  @RequirePermissions(Permission.CHAT_WRITE)
  @ApiOkResponse()
  async createOrGet(
    @Body() body: CreateConversationDto,
  ): Promise<{ conversation: object; created: boolean }> {
    const result = await this.chatService.getOrCreateConversation(
      body.bookingId,
      body.clientId,
      body.establishmentId,
    );
    return { conversation: toConversationDto(result.conversation), created: result.created };
  }

  @Get("me")
  @RequirePermissions(Permission.CHAT_READ)
  @ApiOkResponse()
  async myConversations(
    @CurrentUser() user: AuthenticatedUser,
  ): Promise<object[]> {
    const items = await this.chatService.listConversations(user.sub, user.role);
    return items.map(({ conversation, lastMessage }) => ({
      ...toConversationDto(conversation),
      lastMessage: lastMessage ? toMessageDto(lastMessage) : null,
    }));
  }

  @Get(":id/messages")
  @RequirePermissions(Permission.CHAT_READ)
  @ApiOkResponse()
  async getHistory(
    @Param("id") id: string,
    @CurrentUser() user: AuthenticatedUser,
    @Query("page", new DefaultValuePipe(1), ParseIntPipe) page: number,
    @Query("limit", new DefaultValuePipe(50), ParseIntPipe) limit: number,
  ): Promise<object> {
    const result = await this.chatService.getHistory(id, user.sub, page, limit);
    return {
      messages: result.messages.map(toMessageDto),
      total: result.total,
      page: result.page,
      limit: result.limit,
    };
  }
}
