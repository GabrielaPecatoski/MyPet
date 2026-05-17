import { doublePrecision, pgTable, text, timestamp, uuid } from "drizzle-orm/pg-core";

export const bookingsSchema = pgTable("bookings", {
  id: uuid("id").primaryKey().defaultRandom(),
  userId: uuid("user_id").notNull(),
  userName: text("user_name").notNull().default(""),
  petId: uuid("pet_id").notNull(),
  petName: text("pet_name").notNull(),
  serviceName: text("service_name").notNull(),
  establishmentId: uuid("establishment_id").notNull(),
  establishmentName: text("establishment_name").notNull(),
  scheduledAt: timestamp("scheduled_at", { withTimezone: true }).notNull(),
  price: doublePrecision("price").notNull().default(0),
  status: text("status").notNull().default("PENDENTE"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
