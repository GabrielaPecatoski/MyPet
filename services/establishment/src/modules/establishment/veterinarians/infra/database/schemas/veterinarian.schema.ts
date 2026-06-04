import { pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const veterinariansSchema = pgTable('veterinarians', {
  id: uuid('id').primaryKey().defaultRandom(),
  establishmentId: uuid('establishment_id'),
  name: text('name').notNull(),
  phone: text('phone').notNull(),
  cpf: text('cpf').notNull().unique(),
  crmv: text('crmv').notNull(),
  especialidade: text('especialidade'),
  status: text('status').notNull().default('ATIVO'),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
});
