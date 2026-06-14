CREATE TABLE "complaints" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"user_name" text DEFAULT '' NOT NULL,
	"booking_id" uuid,
	"subject" text NOT NULL,
	"description" text NOT NULL,
	"category" text DEFAULT '' NOT NULL,
	"status" text DEFAULT 'PENDENTE' NOT NULL,
	"response" text,
	"created_at" timestamp with time zone NOT NULL,
	"updated_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "reviews" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"establishment_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"user_name" text DEFAULT '' NOT NULL,
	"booking_id" uuid,
	"rating" integer NOT NULL,
	"comment" text DEFAULT '' NOT NULL,
	"created_at" timestamp with time zone NOT NULL
);
