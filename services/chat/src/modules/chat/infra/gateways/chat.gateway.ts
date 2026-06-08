import { Logger } from "@nestjs/common";
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayDisconnect,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from "@nestjs/websockets";
import { JwtService } from "@nestjs/jwt";
import { Server, Socket } from "socket.io";
import { ChatService } from "../../application/services/chat.service";
import { Message, SenderRole } from "../../domain/models/message.entity";

interface JoinRoomPayload {
  conversationId: string;
}

interface SendMessagePayload {
  conversationId: string;
  content: string;
}

interface MarkReadPayload {
  conversationId: string;
}

interface TypingPayload {
  conversationId: string;
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

@WebSocketGateway({ cors: { origin: "*" }, namespace: "/chat" })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
  ) {}

  handleConnection(client: Socket) {
    const token =
      (client.handshake.auth?.token as string) ||
      (client.handshake.query?.token as string);

    if (!token) {
      this.logger.warn(`Client ${client.id} connected without token — disconnecting`);
      client.disconnect();
      return;
    }

    try {
      const payload = this.jwtService.verify<{ sub: string; role: string }>(token);
      client.data.userId = payload.sub;
      client.data.role = payload.role;
      this.logger.log(`Client connected: ${client.id} (user=${payload.sub})`);
    } catch {
      this.logger.warn(`Client ${client.id} invalid token — disconnecting`);
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    this.logger.log(`Client disconnected: ${client.id}`);
  }

  @SubscribeMessage("joinRoom")
  async handleJoinRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: JoinRoomPayload,
  ) {
    const { userId, role } = client.data as { userId: string; role: string };
    const conv = await this.chatService.findConversationById(data.conversationId);

    if (!conv) {
      client.emit("error", { message: "Conversa não encontrada" });
      return;
    }

    if (role === "CLIENTE" && conv.clientId !== userId) {
      client.emit("error", { message: "Acesso negado" });
      return;
    }

    await client.join(data.conversationId);
    this.logger.log(`User ${userId} joined room ${data.conversationId}`);

    const result = await this.chatService.getHistory(data.conversationId, userId, 1, 50);
    client.emit("history", {
      messages: result.messages.map(toMessageDto),
      total: result.total,
    });
  }

  @SubscribeMessage("sendMessage")
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: SendMessagePayload,
  ) {
    const { userId, role } = client.data as { userId: string; role: string };

    try {
      const message = await this.chatService.sendMessage(
        data.conversationId,
        userId,
        role as SenderRole,
        data.content,
      );
      this.server.to(data.conversationId).emit("newMessage", toMessageDto(message));
    } catch (err) {
      client.emit("error", { message: (err as Error).message });
    }
  }

  @SubscribeMessage("markRead")
  async handleMarkRead(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: MarkReadPayload,
  ) {
    this.server.to(data.conversationId).emit("messagesRead", {
      conversationId: data.conversationId,
    });
  }

  @SubscribeMessage("typing")
  handleTyping(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: TypingPayload,
  ) {
    const { userId } = client.data as { userId: string };
    client.to(data.conversationId).emit("userTyping", { userId });
  }
}
