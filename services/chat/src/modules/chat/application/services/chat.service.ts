import { ForbiddenException, Inject, Injectable, NotFoundException } from "@nestjs/common";
import { Conversation } from "../../domain/models/conversation.entity";
import { Message, SenderRole } from "../../domain/models/message.entity";
import {
  CONVERSATION_REPO,
} from "../../domain/repositories/conversation-repository.interface";
import type { ConversationRepository } from "../../domain/repositories/conversation-repository.interface";
import {
  MESSAGE_REPO,
} from "../../domain/repositories/message-repository.interface";
import type { MessageRepository } from "../../domain/repositories/message-repository.interface";

@Injectable()
export class ChatService {
  constructor(
    @Inject(CONVERSATION_REPO)
    private readonly conversationRepo: ConversationRepository,
    @Inject(MESSAGE_REPO)
    private readonly messageRepo: MessageRepository,
  ) {}

  async getOrCreateConversation(
    bookingId: string,
    clientId: string,
    establishmentId: string,
    clientName?: string,
    establishmentName?: string,
  ): Promise<{ conversation: Conversation; created: boolean }> {
    const existing = await this.conversationRepo.findByBookingId(bookingId);
    if (existing) return { conversation: existing, created: false };

    const conversation = Conversation.create({
      bookingId,
      clientId,
      clientName,
      establishmentId,
      establishmentName,
    });
    const saved = await this.conversationRepo.create(conversation);
    return { conversation: saved, created: true };
  }

  async findConversationById(id: string): Promise<Conversation | null> {
    return this.conversationRepo.findById(id);
  }

  async listConversations(
    userId: string,
    role: string,
  ): Promise<Array<{ conversation: Conversation; lastMessage: Message | null; unreadCount: number }>> {
    const conversations =
      role === "CLIENTE"
        ? await this.conversationRepo.findByClientId(userId)
        : await this.conversationRepo.findByEstablishmentId(userId);

    return Promise.all(
      conversations.map(async (conversation) => {
        const [lastMessage, unreadCount] = await Promise.all([
          this.messageRepo.findLastByConversationId(conversation.id),
          this.messageRepo.countUnread(conversation.id, userId),
        ]);
        return { conversation, lastMessage, unreadCount };
      }),
    );
  }

  async getHistory(
    conversationId: string,
    userId: string,
    page: number,
    limit: number,
  ): Promise<{ messages: Message[]; total: number; page: number; limit: number }> {
    const conv = await this.conversationRepo.findById(conversationId);
    if (!conv) throw new NotFoundException("Conversa não encontrada");
    if (conv.clientId !== userId && conv.establishmentId !== userId) {
      throw new ForbiddenException("Acesso negado a esta conversa");
    }

    const offset = (page - 1) * limit;
    const [messages, total] = await Promise.all([
      this.messageRepo.findByConversationId(conversationId, limit, offset),
      this.messageRepo.countByConversationId(conversationId),
    ]);

    return { messages, total, page, limit };
  }

  async sendMessage(
    conversationId: string,
    senderId: string,
    senderRole: SenderRole,
    content: string,
  ): Promise<Message> {
    const conv = await this.conversationRepo.findById(conversationId);
    if (!conv) throw new NotFoundException("Conversa não encontrada");

    const message = Message.create({ conversationId, senderId, senderRole, content });
    const saved = await this.messageRepo.create(message);
    await this.conversationRepo.touch(conversationId, saved.createdAt);
    return saved;
  }

  async markMessagesRead(conversationId: string, readerId: string): Promise<void> {
    await this.messageRepo.markReadByConversation(conversationId, readerId);
  }
}
