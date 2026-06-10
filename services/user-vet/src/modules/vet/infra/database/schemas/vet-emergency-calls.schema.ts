import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const vetEmergencyCallsSchema = pgTable('vet_emergency_calls', {
  id: uuid('id').primaryKey().defaultRandom(),
  vetId: uuid('vet_id').notNull(),
  callerName: text('caller_name').notNull(),
  callerPhone: text('caller_phone').notNull(),
  petDescription: text('pet_description'),
  status: text('status').notNull().default('PENDING'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull().defaultNow(),
});

export type VetEmergencyCallRecord = typeof vetEmergencyCallsSchema.$inferSelect;
