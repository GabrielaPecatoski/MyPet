-- Adiciona campos veterinários na tabela establishments
ALTER TABLE "establishments"
  ADD COLUMN IF NOT EXISTS "crmv" text,
  ADD COLUMN IF NOT EXISTS "atende_emergencia" boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "atendimento_24h" boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "receber_alerta_sonoro" boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "receber_push_emergencia" boolean NOT NULL DEFAULT false;

-- Adiciona campos de categoria, imagem e status na tabela estab_services
ALTER TABLE "estab_services"
  ADD COLUMN IF NOT EXISTS "categoria" text NOT NULL DEFAULT 'outros',
  ADD COLUMN IF NOT EXISTS "imagem_url" text,
  ADD COLUMN IF NOT EXISTS "ativo" boolean NOT NULL DEFAULT true;
