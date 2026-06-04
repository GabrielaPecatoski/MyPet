import { boolean, doublePrecision, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const bookingsSchema = pgTable("bookings", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull(),
  userName: text("user_name").notNull().default(""),
  petId: uuid("pet_id").notNull(),
  petName: text("pet_name").notNull(),
  serviceName: text("service_name").notNull(),
  servicesJson: text("services_json"),
  establishmentId: uuid("establishment_id").notNull(),
  establishmentName: text("establishment_name").notNull(),
  driverId: uuid("driver_id"),
  driverName: text("driver_name"),
  scheduledAt: timestamp("scheduled_at", { withTimezone: true }).notNull(),
  price: doublePrecision("price").notNull().default(0),
  priceVariable: boolean("price_variable").notNull().default(false),
  status: text("status").notNull().default("PENDENTE"),
  paymentStatus: text("payment_status").notNull().default("NONE"),
  paymentMethod: text("payment_method"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
