import { date, pgTable, text, timestamp, uuid, varchar } from "drizzle-orm/pg-core";

export const usersSchema = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  password: text("password").notNull(),
  phone: varchar("phone", { length: 20 }).notNull(),
  cpf: varchar("cpf", { length: 20 }).notNull().unique(),
  birthDate: date("birth_date"),
  role: varchar("role", { length: 20 }).notNull().default("CLIENTE"),
  permissions: text("permissions").array().notNull().default([]),
  addresses: text("addresses").notNull().default("[]"),
  createdAt: timestamp("created_at", { withTimezone: true }).notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull(),
});
