CREATE TABLE "establishments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"owner_id" uuid NOT NULL,
	"name" text NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"address" text DEFAULT '' NOT NULL,
	"city" text DEFAULT '' NOT NULL,
	"phone" text DEFAULT '' NOT NULL,
	"type" text DEFAULT 'PET_SHOP' NOT NULL,
	"rating" double precision DEFAULT 0 NOT NULL,
	"review_count" integer DEFAULT 0 NOT NULL,
	"image_url" text,
	"crmv" text,
	"atende_emergencia" boolean DEFAULT false NOT NULL,
	"atendimento_24h" boolean DEFAULT false NOT NULL,
	"receber_alerta_sonoro" boolean DEFAULT false NOT NULL,
	"receber_push_emergencia" boolean DEFAULT false NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "estab_services" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid NOT NULL,
	"name" text NOT NULL,
	"price" double precision DEFAULT 0 NOT NULL,
	"price_variable" boolean DEFAULT false NOT NULL,
	"duration_minutes" integer NOT NULL,
	"description" text DEFAULT '' NOT NULL,
	"categoria" text DEFAULT 'outros' NOT NULL,
	"imagem_url" text,
	"ativo" boolean DEFAULT true NOT NULL
);
--> statement-breakpoint
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
--> statement-breakpoint
ALTER TABLE "estab_services" ADD CONSTRAINT "estab_services_establishment_id_establishments_id_fk" FOREIGN KEY ("establishment_id") REFERENCES "public"."establishments"("id") ON DELETE cascade ON UPDATE no action;