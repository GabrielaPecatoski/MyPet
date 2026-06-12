import { establishmentsSchema } from "@estab/establishments/infra/database/schemas/establishment.schema";
import {
  boolean,
  doublePrecision,
  integer,
  pgTable,
  text,
  uuid,
} from "drizzle-orm/pg-core";

export const estabServicesSchema = pgTable("estab_services", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id")
    .notNull()
    .references(() => establishmentsSchema.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  price: doublePrecision("price").notNull().default(0),
  priceVariable: boolean("price_variable").notNull().default(false),
  durationMinutes: integer("duration_minutes").notNull(),
  description: text("description").notNull().default(""),
  categoria: text("categoria").notNull().default("outros"),
  imagemUrl: text("imagem_url"),
  ativo: boolean("ativo").notNull().default(true),
});
