import { productsSchema } from "@market/products/infra/database/schemas/product.schema";
import { integer, pgTable, unique, uuid } from "drizzle-orm/pg-core";

export const cartItemsSchema = pgTable(
  "cart_items",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    userId: uuid("user_id").notNull(),
    productId: uuid("product_id")
      .notNull()
      .references(() => productsSchema.id, { onDelete: "cascade" }),
    quantity: integer("quantity").notNull().default(1),
  },
  (table) => ({
    userProductUniq: unique().on(table.userId, table.productId),
  }),
);
