-- Migração: foto da CNH do motorista visível para o admin.
--
-- A foto do documento passa a ser enviada ao backend (data URL base64, igual à
-- foto de perfil) em vez de ficar só no aparelho do motorista. O admin lê esse
-- campo no painel de verificações para aprovar/rejeitar o cadastro.
--
-- Bancos já existentes não têm a coluna nova (o schema do Drizzle é a fonte da
-- verdade, mas só é aplicado em bancos novos via `drizzle-kit push`). Rode este
-- script contra o Postgres em execução para alinhar os bancos atuais.
--
-- Como aplicar (com a stack no ar):
--   docker exec -i mypet-postgres sh -c 'psql -U "$POSTGRES_USER" -d postgres -v ON_ERROR_STOP=1' < docker/migrations/2026-06-cnh-foto-motorista.sql
--
-- É idempotente (ADD COLUMN IF NOT EXISTS), pode rodar mais de uma vez.

\connect mypet_driver
ALTER TABLE drivers
  ADD COLUMN IF NOT EXISTS cnh_photo_url text;
