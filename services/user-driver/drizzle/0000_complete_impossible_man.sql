CREATE TABLE "drivers" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid NOT NULL,
	"name" text NOT NULL,
	"phone" text NOT NULL,
	"cpf" text NOT NULL,
	"cnh" text NOT NULL,
	"vehicle_type" text NOT NULL,
	"vehicle_model" text NOT NULL,
	"vehicle_plate" text NOT NULL,
	"status" text DEFAULT 'ATIVO' NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL,
	CONSTRAINT "drivers_cpf_unique" UNIQUE("cpf"),
	CONSTRAINT "drivers_vehicle_plate_unique" UNIQUE("vehicle_plate")
);
