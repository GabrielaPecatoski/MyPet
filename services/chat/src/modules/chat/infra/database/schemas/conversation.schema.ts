import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const conversationsSchema = pgTable("conversations", {
  id: uuid("id").primaryKey().defaultRandom(),
  bookingId: text("booking_id").notNull().unique(),
  clientId: text("client_id").notNull(),
  clientName: text("client_name").notNull().default(""),
  establishmentId: text("establishment_id").notNull(),
  establishmentName: text("establishment_name").notNull().default(""),
  lastMessageAt: timestamp("last_message_at", { withTimezone: true }),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});
