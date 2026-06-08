import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const conversationsSchema = pgTable("conversations", {
  id: uuid("id").primaryKey().defaultRandom(),
  bookingId: text("booking_id").notNull().unique(),
  clientId: text("client_id").notNull(),
  establishmentId: text("establishment_id").notNull(),
  lastMessageAt: timestamp("last_message_at", { withTimezone: true }),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
