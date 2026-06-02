import { doublePrecision, integer, pgTable, text, uuid } from "drizzle-orm/pg-core";
import { establishmentsSchema } from "@estab/establishments/infra/database/schemas/establishment.schema";

export const estabServicesSchema = pgTable("estab_services", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id")
    .notNull()
    .references(() => establishmentsSchema.id, { onDelete: "cascade" }),
  name: text("name").notNull(),
  price: doublePrecision("price").notNull(),
  durationMinutes: integer("duration_minutes").notNull(),
  description: text("description").notNull().default(""),
});
