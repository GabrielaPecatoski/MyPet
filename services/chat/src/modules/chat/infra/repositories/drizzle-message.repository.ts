import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { and, asc, count, desc, eq, isNull, ne } from "drizzle-orm";
import { Message, SenderRole } from "../../domain/models/message.entity";
import { MessageRepository } from "../../domain/repositories/message-repository.interface";
import { messagesSchema } from "../database/schemas/message.schema";

@Injectable()
export class DrizzleMessageRepository implements MessageRepository {
  constructor(private readonly drizzle: DrizzleService) {}

  private toEntity(row: typeof messagesSchema.$inferSelect): Message {
    return Message.restore({
      id: row.id,
      conversationId: row.conversationId,
      senderId: row.senderId,
      senderRole: row.senderRole as SenderRole,
      content: row.content,
      readAt: row.readAt ?? null,
      createdAt: row.createdAt,
    });
  }

  async create(message: Message): Promise<Message> {
    const [row] = await this.drizzle.db
      .insert(messagesSchema)
      .values({
        id: message.id,
        conversationId: message.conversationId,
        senderId: message.senderId,
        senderRole: message.senderRole,
        content: message.content,
        readAt: message.readAt,
        createdAt: message.createdAt,
      })
      .returning();
    return this.toEntity(row);
  }

  async findByConversationId(
    conversationId: string,
    limit: number,
    offset: number,
  ): Promise<Message[]> {
    const rows = await this.drizzle.db
      .select()
      .from(messagesSchema)
      .where(eq(messagesSchema.conversationId, conversationId))
      .orderBy(asc(messagesSchema.createdAt))
      .limit(limit)
      .offset(offset);
    return rows.map((r) => this.toEntity(r));
  }

  async findLastByConversationId(conversationId: string): Promise<Message | null> {
    const [row] = await this.drizzle.db
      .select()
      .from(messagesSchema)
      .where(eq(messagesSchema.conversationId, conversationId))
      .orderBy(desc(messagesSchema.createdAt))
      .limit(1);
    return row ? this.toEntity(row) : null;
  }

  async countByConversationId(conversationId: string): Promise<number> {
    const [row] = await this.drizzle.db
      .select({ count: count() })
      .from(messagesSchema)
      .where(eq(messagesSchema.conversationId, conversationId));
    return Number(row?.count ?? 0);
  }

  async markReadByConversation(conversationId: string, readerId: string): Promise<void> {
    await this.drizzle.db
      .update(messagesSchema)
      .set({ readAt: new Date() })
      .where(
        and(
          eq(messagesSchema.conversationId, conversationId),
          ne(messagesSchema.senderId, readerId),
          isNull(messagesSchema.readAt),
        ),
      );
  }

  async countUnread(conversationId: string, userId: string): Promise<number> {
    const [row] = await this.drizzle.db
      .select({ count: count() })
      .from(messagesSchema)
      .where(
        and(
          eq(messagesSchema.conversationId, conversationId),
          ne(messagesSchema.senderId, userId),
          isNull(messagesSchema.readAt),
        ),
      );
    return Number(row?.count ?? 0);
  }
}
