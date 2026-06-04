import { boolean, doublePrecision, integer, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const establishmentsSchema = pgTable("establishments", {
  id: uuid("id").primaryKey().defaultRandom(),
  ownerId: uuid("owner_id").notNull(),
  name: text("name").notNull(),
  description: text("description").notNull().default(""),
  address: text("address").notNull().default(""),
  city: text("city").notNull().default(""),
  phone: text("phone").notNull().default(""),
  type: text("type").notNull().default("PET_SHOP"),
  rating: doublePrecision("rating").notNull().default(0),
  reviewCount: integer("review_count").notNull().default(0),
  imageUrl: text("image_url"),
  crmv: text("crmv"),
  atendeEmergencia: boolean("atende_emergencia").notNull().default(false),
  atendimento24h: boolean("atendimento_24h").notNull().default(false),
  receberAlertaSonoro: boolean("receber_alerta_sonoro").notNull().default(false),
  receberPushEmergencia: boolean("receber_push_emergencia").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
