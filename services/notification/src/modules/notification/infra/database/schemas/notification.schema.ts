import { boolean, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const notificationsSchema = pgTable("notifications", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: text("user_id").notNull(),
  title: text("title").notNull(),
  body: text("body").notNull(),
  type: text("type").notNull(),
  read: boolean("read").notNull().default(false),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});

export type NotificationRecord = typeof notificationsSchema.$inferSelect;
