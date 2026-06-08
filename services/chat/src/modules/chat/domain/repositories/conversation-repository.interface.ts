import { Conversation } from "../models/conversation.entity";

export interface ConversationRepository {
  findById(id: string): Promise<Conversation | null>;
  findByBookingId(bookingId: string): Promise<Conversation | null>;
  findByClientId(clientId: string): Promise<Conversation[]>;
  findByEstablishmentId(establishmentId: string): Promise<Conversation[]>;
  create(conversation: Conversation): Promise<Conversation>;
  touch(id: string, lastMessageAt: Date): Promise<void>;
}

export const CONVERSATION_REPO = Symbol("ConversationRepository");
