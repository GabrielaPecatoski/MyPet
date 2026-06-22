-- Migração: data de nascimento do usuário (validação de maioridade no cadastro).
--
-- Todo cadastro passa a coletar a data de nascimento; o backend recusa quem tem
-- menos de 18 anos. A coluna é a fonte da verdade no banco de auth.
--
-- Bancos já existentes não têm a coluna nova (o schema do Drizzle é a fonte da
-- verdade, mas só é aplicado em bancos novos via migrate). Rode este script
-- contra o Postgres em execução para alinhar os bancos atuais.
--
-- Como aplicar (com a stack no ar):
--   docker exec -i mypet-postgres sh -c 'psql -U "$POSTGRES_USER" -h 127.0.0.1 -d postgres -v ON_ERROR_STOP=1' < docker/migrations/2026-06-data-nascimento.sql
--
-- É idempotente (ADD COLUMN IF NOT EXISTS), pode rodar mais de uma vez.

\connect mypet_auth
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS birth_date date;
