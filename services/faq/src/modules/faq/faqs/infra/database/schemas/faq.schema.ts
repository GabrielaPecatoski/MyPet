import {
  boolean,
  integer,
  pgTable,
  text,
  timestamp,
  uuid,
} from "drizzle-orm/pg-core";

export const faqItemsSchema = pgTable("faq_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  question: text("question").notNull(),
  answer: text("answer").notNull(),
  category: text("category").notNull().default(""),
  targetRole: text("target_role").notNull().default("CLIENTE"),
  order: integer("order").notNull().default(0),
  active: boolean("active").notNull().default(true),
  viewCount: integer("view_count").notNull().default(0),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
});
