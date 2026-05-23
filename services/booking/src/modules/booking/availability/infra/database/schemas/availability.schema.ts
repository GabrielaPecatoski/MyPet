import { boolean, integer, pgTable, text, uniqueIndex, uuid } from "drizzle-orm/pg-core";

export const schedulesSchema = pgTable(
  "schedules",
  {
    id: uuid("id").primaryKey().defaultRandom(),
    establishmentId: uuid("establishment_id").notNull(),
    dayOfWeek: integer("day_of_week").notNull(),
    openTime: text("open_time").notNull(),
    closeTime: text("close_time").notNull(),
    slotDuration: integer("slot_duration").notNull().default(30),
    isOpen: boolean("is_open").notNull().default(true),
    capacity: integer("capacity").notNull().default(1),
  },
  (t) => [uniqueIndex("schedules_estab_day_uidx").on(t.establishmentId, t.dayOfWeek)],
);

export const blockedSlotsSchema = pgTable("blocked_slots", {
  id: uuid("id").primaryKey().defaultRandom(),
  establishmentId: uuid("establishment_id").notNull(),
  date: text("date").notNull(),
  startTime: text("start_time").notNull(),
  endTime: text("end_time").notNull(),
  reason: text("reason"),
});
