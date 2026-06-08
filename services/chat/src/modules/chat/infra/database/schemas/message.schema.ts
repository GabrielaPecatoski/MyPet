import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";
import { conversationsSchema } from "./conversation.schema";

export const messagesSchema = pgTable("messages", {
  id: uuid("id").primaryKey().defaultRandom(),
  conversationId: uuid("conversation_id")
    .notNull()
    .references(() => conversationsSchema.id),
  senderId: text("sender_id").notNull(),
  senderRole: text("sender_role").notNull(),
  content: text("content").notNull(),
  readAt: timestamp("read_at", { withTimezone: true }),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
