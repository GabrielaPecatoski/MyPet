import { EstabService } from "@estab/services/domain/models/estab-service.entity";
import type { EstabServiceRepository } from "@estab/services/domain/repositories/estab-service-repository.interface";
import { estabServicesSchema } from "@estab/services/infra/database/schemas/estab-service.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DrizzleEstabServiceRepository implements EstabServiceRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(service: EstabService): Promise<void> {
    await this.drizzleService.db.insert(estabServicesSchema).values({
      establishmentId: service.establishmentId,
      name: service.name,
      price: service.price,
      durationMinutes: service.durationMinutes,
      description: service.description,
    });
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(estabServicesSchema).where(eq(estabServicesSchema.id, id));
  }

  async findByEstablishmentId(establishmentId: string): Promise<EstabService[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(estabServicesSchema)
      .where(eq(estabServicesSchema.establishmentId, establishmentId));
    return rows.map((r) => EstabService.restore(r)!);
  }

  async findById(id: string): Promise<EstabService | null> {
    const result = await this.drizzleService.db
      .select()
      .from(estabServicesSchema)
      .where(eq(estabServicesSchema.id, id))
      .limit(1);
    return EstabService.restore(result[0]);
  }
}
