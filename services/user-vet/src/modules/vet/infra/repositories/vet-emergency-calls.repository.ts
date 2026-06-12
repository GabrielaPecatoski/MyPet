import { Injectable, Logger, OnModuleInit } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import {
  type VetEmergencyCallRecord,
  vetEmergencyCallsSchema,
} from "@vet/vet/infra/database/schemas/vet-emergency-calls.schema";
import { and, desc, eq, gt, sql } from "drizzle-orm";

const CALL_TTL_MS = 10 * 60 * 1000; // 10 minutes

@Injectable()
export class VetEmergencyCallsRepository implements OnModuleInit {
  private readonly logger = new Logger(VetEmergencyCallsRepository.name);

  constructor(private readonly drizzleService: DrizzleService) {}

  async onModuleInit(): Promise<void> {
    try {
      await this.drizzleService.db.execute(sql`
        CREATE TABLE IF NOT EXISTS vet_emergency_calls (
          id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
          vet_id      UUID        NOT NULL,
          caller_name TEXT        NOT NULL,
          caller_phone TEXT       NOT NULL,
          pet_description TEXT,
          status      TEXT        NOT NULL DEFAULT 'PENDING',
          created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
      `);
      this.logger.log("vet_emergency_calls table ready");
    } catch (err) {
      this.logger.error("Failed to create vet_emergency_calls table", err);
    }
  }

  async create(data: {
    vetId: string;
    callerName: string;
    callerPhone: string;
    petDescription?: string;
  }): Promise<VetEmergencyCallRecord> {
    const [row] = await this.drizzleService.db
      .insert(vetEmergencyCallsSchema)
      .values({
        vetId: data.vetId,
        callerName: data.callerName,
        callerPhone: data.callerPhone,
        petDescription: data.petDescription ?? null,
      })
      .returning();
    return row;
  }

  async findPending(vetId: string): Promise<VetEmergencyCallRecord[]> {
    const cutoff = new Date(Date.now() - CALL_TTL_MS);
    return this.drizzleService.db
      .select()
      .from(vetEmergencyCallsSchema)
      .where(
        and(
          eq(vetEmergencyCallsSchema.vetId, vetId),
          eq(vetEmergencyCallsSchema.status, "PENDING"),
          gt(vetEmergencyCallsSchema.createdAt, cutoff),
        ),
      )
      .orderBy(desc(vetEmergencyCallsSchema.createdAt));
  }

  async acknowledge(callId: string): Promise<void> {
    await this.drizzleService.db
      .update(vetEmergencyCallsSchema)
      .set({ status: "ACKNOWLEDGED" })
      .where(eq(vetEmergencyCallsSchema.id, callId));
  }
}
