import { integer, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const reviewsSchema = pgTable("reviews", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id").notNull(),
  userId: uuid("user_id").notNull(),
  userName: text("user_name").notNull().default(""),
  bookingId: uuid("booking_id"),
  rating: integer("rating").notNull(),
  comment: text("comment").notNull().default(""),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
});
