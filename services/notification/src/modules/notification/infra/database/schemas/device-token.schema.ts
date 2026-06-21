import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const deviceTokensSchema = pgTable("device_tokens", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: text("user_id").notNull().unique(),
  token: text("token").notNull(),
  platform: text("platform").notNull().default("android"),
  createdAt: timestamp("created_at").notNull().defaultNow(),
});
