import {
  doublePrecision,
  integer,
  pgTable,
  text,
  timestamp,
  uuid,
} from "drizzle-orm/pg-core";

export const ordersSchema = pgTable("orders", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull(),
  establishmentId: uuid("establishment_id"),
  total: doublePrecision("total").notNull(),
  status: text("status").notNull().default("AGUARDANDO_PAGAMENTO"),
  deliveryMethod: text("delivery_method").notNull().default("PICKUP"),
  deliveryAddress: text("delivery_address"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
});

export const orderItemsSchema = pgTable("order_items", {
  id: uuid("id").primaryKey().defaultRandom(),
  orderId: uuid("order_id")
    .notNull()
    .references(() => ordersSchema.id, { onDelete: "cascade" }),
  productId: uuid("product_id").notNull(),
  quantity: integer("quantity").notNull(),
  price: doublePrecision("price").notNull(),
});
