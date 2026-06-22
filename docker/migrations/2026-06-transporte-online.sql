-- Migração: "online real" do motorista + status de transporte da corrida.
--
-- Bancos já existentes não têm as colunas novas (o schema do Drizzle é a fonte
-- da verdade, mas só é aplicado em bancos novos via `drizzle-kit push`). Rode
-- este script contra o Postgres em execução para alinhar os bancos atuais.
--
-- Como aplicar (com a stack no ar):
--   docker exec -i mypet-postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1' < docker/migrations/2026-06-transporte-online.sql
--
-- É idempotente (ADD COLUMN IF NOT EXISTS), pode rodar mais de uma vez.

\connect mypet_auth
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS addresses text NOT NULL DEFAULT '[]';

\connect mypet_driver
ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS online boolean NOT NULL DEFAULT false;

\connect mypet_booking
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS transport_status text NOT NULL DEFAULT 'NONE';
ALTER TABLE bookings
  ADD COLUMN IF NOT EXISTS pet_photo_url text;
