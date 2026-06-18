CREATE TABLE "blocked_slots" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid NOT NULL,
	"date" text NOT NULL,
	"start_time" text NOT NULL,
	"end_time" text NOT NULL,
	"reason" text
);
--> statement-breakpoint
CREATE TABLE "schedules" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid NOT NULL,
	"day_of_week" integer NOT NULL,
	"open_time" text NOT NULL,
	"close_time" text NOT NULL,
	"slot_duration" integer DEFAULT 30 NOT NULL,
	"is_open" boolean DEFAULT true NOT NULL,
	"capacity" integer DEFAULT 1 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "bookings" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"user_name" text DEFAULT '' NOT NULL,
	"pet_id" uuid NOT NULL,
	"pet_name" text NOT NULL,
	"service_name" text NOT NULL,
	"services_json" text,
	"establishment_id" uuid,
	"establishment_name" text DEFAULT '' NOT NULL,
	"driver_id" uuid,
	"driver_name" text,
	"vet_id" uuid,
	"vet_name" text,
	"scheduled_at" timestamp with time zone NOT NULL,
	"price" double precision DEFAULT 0 NOT NULL,
	"price_variable" boolean DEFAULT false NOT NULL,
	"status" text DEFAULT 'PENDENTE' NOT NULL,
	"payment_status" text DEFAULT 'NONE' NOT NULL,
	"payment_method" text,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE UNIQUE INDEX "schedules_estab_day_uidx" ON "schedules" USING btree ("establishment_id","day_of_week");