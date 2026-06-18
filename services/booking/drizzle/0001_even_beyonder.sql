ALTER TABLE "blocked_slots" ALTER COLUMN "establishment_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "schedules" ALTER COLUMN "establishment_id" DROP NOT NULL;--> statement-breakpoint
ALTER TABLE "blocked_slots" ADD COLUMN "vet_id" uuid;--> statement-breakpoint
ALTER TABLE "schedules" ADD COLUMN "vet_id" uuid;--> statement-breakpoint
CREATE UNIQUE INDEX "schedules_vet_day_uidx" ON "schedules" USING btree ("vet_id","day_of_week");