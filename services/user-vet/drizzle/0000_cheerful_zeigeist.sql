CREATE TABLE "veterinarians" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid,
	"name" text NOT NULL,
	"phone" text NOT NULL,
	"cpf" text NOT NULL,
	"crmv" text NOT NULL,
	"especialidade" text,
	"status" text DEFAULT 'PENDENTE' NOT NULL,
	"disponivel" boolean DEFAULT false NOT NULL,
	"atende_domicilio" boolean DEFAULT false NOT NULL,
	"atende_24h" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL,
	CONSTRAINT "veterinarians_cpf_unique" UNIQUE("cpf")
);
