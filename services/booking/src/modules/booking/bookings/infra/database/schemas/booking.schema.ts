import {
  doublePrecision,
  integer,
  pgTable,
  text,
  timestamp,
  uuid,
} from "drizzle-orm/pg-core";

export const bookingsSchema = pgTable("bookings", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull(),
  userName: text("user_name").notNull().default(""),
  userEmail: text("user_email"),
  petId: uuid("pet_id").notNull(),
  petName: text("pet_name").notNull(),
  petBreed: text("pet_breed").default(""),
  petAge: integer("pet_age").default(0),
  serviceName: text("service_name").notNull(),
  servicesJson: text("services_json"),
  establishmentId: uuid("establishment_id").notNull(),
  establishmentName: text("establishment_name").notNull(),
  establishmentAddress: text("establishment_address").default(""),
  scheduledAt: timestamp("scheduled_at", { withTimezone: true }).notNull(),
  price: doublePrecision("price").notNull().default(0),
  status: text("status").notNull().default("PENDENTE"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
