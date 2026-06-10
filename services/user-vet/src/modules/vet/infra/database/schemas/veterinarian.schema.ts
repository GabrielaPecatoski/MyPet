import { boolean, pgTable, text, timestamp, uuid } from 'drizzle-orm/pg-core';

export const veterinariansSchema = pgTable('veterinarians', {
  id: uuid('id').primaryKey().defaultRandom(),
  establishmentId: uuid('establishment_id'),
  name: text('name').notNull(),
  phone: text('phone').notNull(),
  cpf: text('cpf').notNull().unique(),
  crmv: text('crmv').notNull(),
  especialidade: text('especialidade'),
  status: text('status').notNull().default('PENDENTE'),
  disponivel: boolean('disponivel').notNull().default(false),
  atendeDomicilio: boolean('atende_domicilio').notNull().default(false),
  atende24h: boolean('atende_24h').notNull().default(false),
  createdAt: timestamp('created_at', { withTimezone: true }).notNull(),
  updatedAt: timestamp('updated_at', { withTimezone: true }).notNull(),
});
