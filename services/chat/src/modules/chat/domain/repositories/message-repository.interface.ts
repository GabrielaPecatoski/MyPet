import { Message } from "../models/message.entity";

export interface MessageRepository {
  create(message: Message): Promise<Message>;
  findByConversationId(
    conversationId: string,
    limit: number,
    offset: number,
  ): Promise<Message[]>;
  findLastByConversationId(conversationId: string): Promise<Message | null>;
  countByConversationId(conversationId: string): Promise<number>;
}

export const MESSAGE_REPO = Symbol("MessageRepository");
