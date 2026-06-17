import {
  doublePrecision,
  integer,
  pgTable,
  text,
  timestamp,
  uuid,
} from "drizzle-orm/pg-core";

export const petsSchema = pgTable("pets", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull(),
  name: text("name").notNull(),
  type: text("type").notNull(),
  breed: text("breed").notNull(),
  age: integer("age").notNull(),
  weight: doublePrecision("weight").notNull(),
  imageUrl: text("image_url"),
  notes: text("notes"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
