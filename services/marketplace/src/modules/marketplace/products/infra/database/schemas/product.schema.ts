import { boolean, doublePrecision, integer, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const productsSchema = pgTable("products", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id"),
  name: text("name").notNull(),
  brand: text("brand").notNull().default(""),
  price: doublePrecision("price").notNull(),
  unit: text("unit").notNull().default("Un"),
  category: text("category").notNull().default(""),
  description: text("description").notNull().default(""),
  stock: integer("stock").notNull().default(0),
  imageUrl: text("image_url"),
  active: boolean("active").notNull().default(true),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
});
