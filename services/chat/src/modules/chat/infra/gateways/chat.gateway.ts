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

interface JoinRoomPayload   { conversationId: string }
interface SendMessagePayload { conversationId: string; content: string }
interface MarkReadPayload   { conversationId: string }
interface TypingPayload     { conversationId: string }
interface LeaveRoomPayload  { conversationId: string }

function toMessageDto(m: Message) {
  return {
    id:             m.id,
    conversationId: m.conversationId,
    senderId:       m.senderId,
    senderRole:     m.senderRole,
    content:        m.content,
    readAt:         m.readAt,
    createdAt:      m.createdAt,
  };
}

@WebSocketGateway({ cors: { origin: "*" }, namespace: "/chat" })
export class ChatGateway implements OnGatewayConnection, OnGatewayDisconnect {
  @WebSocketServer() server: Server;

  private readonly logger = new Logger(ChatGateway.name);

  // userId → Set de socketIds (suporte a múltiplas abas)
  private readonly onlineUsers = new Map<string, Set<string>>();

  constructor(
    private readonly chatService: ChatService,
    private readonly jwtService: JwtService,
  ) {}

  // ─── Ciclo de vida ───────────────────────────────────────────────────────────

  handleConnection(client: Socket) {
    const token =
      (client.handshake.auth?.token as string) ||
      (client.handshake.query?.token as string);

    if (!token) {
      client.disconnect();
      return;
    }

    try {
      const payload = this.jwtService.verify<{ sub: string; role: string }>(token);
      client.data.userId = payload.sub;
      client.data.role   = payload.role;

      // Registra presença
      if (!this.onlineUsers.has(payload.sub)) {
        this.onlineUsers.set(payload.sub, new Set());
      }
      this.onlineUsers.get(payload.sub)!.add(client.id);

      this.logger.log(`Connected: ${client.id} (user=${payload.sub})`);
    } catch {
      client.disconnect();
    }
  }

  handleDisconnect(client: Socket) {
    const userId = client.data?.userId as string | undefined;
    if (userId) {
      const sockets = this.onlineUsers.get(userId);
      if (sockets) {
        sockets.delete(client.id);
        if (sockets.size === 0) {
          this.onlineUsers.delete(userId);
          // client.rooms is empty at this point; use the tracked set from client.data
          const joinedRooms = client.data.joinedRooms as Set<string> | undefined;
          if (joinedRooms) {
            for (const room of joinedRooms) {
              this.server.to(room).emit("partnerStatus", { userId, online: false });
            }
          }
        }
      }
    }
    this.logger.log(`Disconnected: ${client.id}`);
  }

  // ─── Helpers de presença ─────────────────────────────────────────────────────

  private isOnline(userId: string): boolean {
    const sockets = this.onlineUsers.get(userId);
    return !!sockets && sockets.size > 0;
  }

  // ─── Eventos ─────────────────────────────────────────────────────────────────

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
    if (role === "CLIENTE"  && conv.clientId        !== userId) {
      client.emit("error", { message: "Acesso negado" });
      return;
    }
    if (role === "VENDEDOR" && conv.establishmentId !== userId) {
      client.emit("error", { message: "Acesso negado" });
      return;
    }

    await client.join(data.conversationId);
    if (!client.data.joinedRooms) client.data.joinedRooms = new Set<string>();
    (client.data.joinedRooms as Set<string>).add(data.conversationId);
    this.logger.log(`User ${userId} joined room ${data.conversationId}`);

    // Histórico de mensagens
    const result = await this.chatService.getHistory(data.conversationId, userId, 1, 50);
    client.emit("history", {
      messages: result.messages.map(toMessageDto),
      total:    result.total,
    });

    // Informa ao usuário o status online do parceiro
    const partnerId =
      role === "CLIENTE" ? conv.establishmentId : conv.clientId;
    client.emit("partnerStatus", { userId: partnerId, online: this.isOnline(partnerId) });

    // Informa ao parceiro (se online) que este usuário entrou
    client.to(data.conversationId).emit("partnerStatus", { userId, online: true });
  }

  @SubscribeMessage("leaveRoom")
  async handleLeaveRoom(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: LeaveRoomPayload,
  ) {
    await client.leave(data.conversationId);
    const { userId } = client.data as { userId: string };
    (client.data.joinedRooms as Set<string> | undefined)?.delete(data.conversationId);
    client.to(data.conversationId).emit("partnerStatus", { userId, online: false });
    this.logger.log(`User ${userId} left room ${data.conversationId}`);
  }

  @SubscribeMessage("sendMessage")
  async handleSendMessage(
    @ConnectedSocket() client: Socket,
    @MessageBody() data: SendMessagePayload,
  ) {
    const { userId, role } = client.data as { userId: string; role: string };

    // Só pode enviar se entrou na sala (passou pela validação de acesso)
    if (!client.rooms.has(data.conversationId)) {
      client.emit("error", { message: "Entre na conversa antes de enviar mensagens" });
      return;
    }

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
    const { userId } = client.data as { userId: string };
    await this.chatService.markMessagesRead(data.conversationId, userId);
    const readAt = new Date().toISOString();
    // Inclui readAt para o remetente atualizar o check das mensagens
    this.server.to(data.conversationId).emit("messagesRead", {
      conversationId: data.conversationId,
      readerId: userId,
      readAt,
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
