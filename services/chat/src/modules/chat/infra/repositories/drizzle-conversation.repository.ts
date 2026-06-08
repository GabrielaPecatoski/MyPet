import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";
import { Conversation } from "../../domain/models/conversation.entity";
import { ConversationRepository } from "../../domain/repositories/conversation-repository.interface";
import { conversationsSchema } from "../database/schemas/conversation.schema";

@Injectable()
export class DrizzleConversationRepository implements ConversationRepository {
  constructor(private readonly drizzle: DrizzleService) {}

  private toEntity(row: typeof conversationsSchema.$inferSelect): Conversation {
    return Conversation.restore({
      id: row.id,
      bookingId: row.bookingId,
      clientId: row.clientId,
      establishmentId: row.establishmentId,
      lastMessageAt: row.lastMessageAt ?? null,
      createdAt: row.createdAt,
    });
  }

  async findById(id: string): Promise<Conversation | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(conversationsSchema)
      .where(eq(conversationsSchema.id, id));
    return row ? this.toEntity(row) : null;
  }

  async findByBookingId(bookingId: string): Promise<Conversation | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(conversationsSchema)
      .where(eq(conversationsSchema.bookingId, bookingId));
    return row ? this.toEntity(row) : null;
  }

  async findByClientId(clientId: string): Promise<Conversation[]> {
    const rows = await this.drizzle.db
      .select()
      .from(conversationsSchema)
      .where(eq(conversationsSchema.clientId, clientId));
    return rows.map((r) => this.toEntity(r));
  }

  async findByEstablishmentId(establishmentId: string): Promise<Conversation[]> {
    const rows = await this.drizzle.db
      .select()
      .from(conversationsSchema)
      .where(eq(conversationsSchema.establishmentId, establishmentId));
    return rows.map((r) => this.toEntity(r));
  }

  async create(conversation: Conversation): Promise<Conversation> {
    const [row] = await this.drizzle.db
      .insert(conversationsSchema)
      .values({
        id: conversation.id,
        bookingId: conversation.bookingId,
        clientId: conversation.clientId,
        establishmentId: conversation.establishmentId,
        lastMessageAt: conversation.lastMessageAt,
        createdAt: conversation.createdAt,
      })
      .returning();
    return this.toEntity(row);
  }

  async touch(id: string, lastMessageAt: Date): Promise<void> {
    await this.drizzle.db
      .update(conversationsSchema)
      .set({ lastMessageAt })
      .where(eq(conversationsSchema.id, id));
  }
}
