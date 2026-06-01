import { pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const driversSchema = pgTable("drivers", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id"),
  name: text("name").notNull(),
  phone: text("phone").notNull(),
  cpf: text("cpf").notNull().unique(),
  cnh: text("cnh").notNull(),
  vehicleType: text("vehicle_type").notNull(),
  vehicleModel: text("vehicle_model").notNull(),
  vehiclePlate: text("vehicle_plate").notNull().unique(),
  status: text("status").notNull().default("ATIVO"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
