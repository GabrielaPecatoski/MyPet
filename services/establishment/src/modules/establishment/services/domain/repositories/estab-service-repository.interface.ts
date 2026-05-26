import type { EstabService } from "@estab/services/domain/models/estab-service.entity";

export const ESTAB_SERVICE_REPOSITORY = Symbol("ESTAB_SERVICE_REPOSITORY");

export interface EstabServiceRepository {
  create(service: EstabService): Promise<void>;
  delete(id: string): Promise<void>;
  findByEstablishmentId(establishmentId: string): Promise<EstabService[]>;
  findById(id: string): Promise<EstabService | null>;
}
