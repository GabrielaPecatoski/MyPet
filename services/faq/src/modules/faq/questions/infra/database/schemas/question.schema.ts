import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const userQuestionsSchema = pgTable("user_questions", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull(),
  userName: text("user_name").notNull(),
  userRole: text("user_role").notNull().default("CLIENTE"),
  question: text("question").notNull(),
  answer: text("answer"),
  status: text("status").notNull().default("PENDENTE"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  answeredAt: timestamp("answered_at", { withTimezone: true }),
});
