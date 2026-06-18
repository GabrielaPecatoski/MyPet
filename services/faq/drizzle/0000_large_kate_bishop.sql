CREATE TABLE "faq_items" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"question" text NOT NULL,
	"answer" text NOT NULL,
	"category" text DEFAULT '' NOT NULL,
	"target_role" text DEFAULT 'CLIENTE' NOT NULL,
	"order" integer DEFAULT 0 NOT NULL,
	"active" boolean DEFAULT true NOT NULL,
	"view_count" integer DEFAULT 0 NOT NULL,
	"created_at" timestamp with time zone NOT NULL
);
--> statement-breakpoint
CREATE TABLE "user_questions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"user_name" text NOT NULL,
	"user_role" text DEFAULT 'CLIENTE' NOT NULL,
	"question" text NOT NULL,
	"answer" text,
	"status" text DEFAULT 'PENDENTE' NOT NULL,
	"created_at" timestamp with time zone NOT NULL,
	"answered_at" timestamp with time zone
);
