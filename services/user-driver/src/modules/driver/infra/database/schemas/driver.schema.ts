import { boolean, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

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
  photoUrl: text("photo_url"),
  cnhPhotoUrl: text("cnh_photo_url"),
  status: text("status").notNull().default("PENDENTE"),
  online: boolean("online").notNull().default(false),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
