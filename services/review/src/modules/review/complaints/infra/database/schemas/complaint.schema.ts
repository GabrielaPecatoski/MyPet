import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const complaintsSchema = pgTable("complaints", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id").notNull(),
  userId: uuid("user_id").notNull(),
  userName: text("user_name").notNull().default(""),
  bookingId: uuid("booking_id"),
  subject: text("subject").notNull(),
  description: text("description").notNull(),
  category: text("category").notNull().default(""),
  status: text("status").notNull().default("PENDENTE"),
  response: text("response"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
