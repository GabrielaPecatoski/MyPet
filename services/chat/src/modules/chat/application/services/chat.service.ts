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
    // O app envia o ID da ENTIDADE estabelecimento (booking/order), mas o
    // VENDEDOR se autentica com o seu próprio user id (JWT sub). A conversa
    // precisa ser indexada pelo user id do dono para que o estabelecimento
    // consiga LISTAR (GET /conversations/me) e ENTRAR (joinRoom) nos seus chats.
    const estab = await this.resolveEstablishment(establishmentId);
    const establishmentUserId = estab?.ownerId ?? establishmentId;
    const resolvedName = establishmentName?.trim()
      ? establishmentName
      : estab?.name;

    // Uma conversa por par (cliente, estabelecimento): pedidos e agendamentos
    // com o mesmo estabelecimento compartilham o mesmo chat, que persiste depois
    // de o pedido terminar. O bookingId fica só como referência da 1ª origem.
    const existing = await this.conversationRepo.findByClientAndEstablishment(
      clientId,
      establishmentUserId,
    );
    if (existing) {
      return {
        conversation: await this.backfillEstablishmentName(
          existing,
          resolvedName,
        ),
        created: false,
      };
    }

    const conversation = Conversation.create({
      bookingId,
      clientId,
      clientName,
      establishmentId: establishmentUserId,
      establishmentName: resolvedName,
    });
    const saved = await this.conversationRepo.create(conversation);
    return { conversation: saved, created: true };
  }

  /// Preenche o nome do estabelecimento quando vazio (conversas criadas a partir
  /// de pedidos da loja não trazem o nome), persistindo o nome já resolvido.
  private async backfillEstablishmentName(
    conv: Conversation,
    name?: string,
  ): Promise<Conversation> {
    if (conv.establishmentName?.trim() || !name?.trim()) return conv;
    await this.conversationRepo.updateEstablishmentName(conv.id, name);
    return (await this.conversationRepo.findById(conv.id)) ?? conv;
  }

  /// Resolve o ID da entidade estabelecimento no user id do dono (ownerId) e no
  /// nome, consultando o serviço de estabelecimentos (rota pública /v1).
  private async resolveEstablishment(
    establishmentId: string,
  ): Promise<{ ownerId?: string; name?: string } | undefined> {
    const base =
      process.env.ESTABLISHMENT_SERVICE_URL ?? "http://establishment:3003";
    try {
      const res = await fetch(`${base}/v1/establishments/${establishmentId}`, {
        signal: AbortSignal.timeout(3000),
      });
      if (!res.ok) return undefined;
      const data = (await res.json()) as { ownerId?: string; name?: string };
      return {
        ownerId: data?.ownerId?.trim() ? data.ownerId : undefined,
        name: data?.name?.trim() ? data.name : undefined,
      };
    } catch {
      return undefined;
    }
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
