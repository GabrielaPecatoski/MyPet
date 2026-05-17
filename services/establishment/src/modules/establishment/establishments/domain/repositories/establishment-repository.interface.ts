import type { Establishment } from "@estab/establishments/domain/models/establishment.entity";
import type { PaginationParams } from "@shared/infra/hateoas";

export const ESTABLISHMENT_REPOSITORY = Symbol("ESTABLISHMENT_REPOSITORY");

export interface EstablishmentRepository {
  create(establishment: Establishment): Promise<void>;
  update(establishment: Establishment): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Establishment | null>;
  findByOwnerId(ownerId: string): Promise<Establishment[]>;
  findAll(search?: string): Promise<Establishment[]>;
  findAllPaginated(params: PaginationParams, search?: string): Promise<{ rows: Establishment[]; total: number }>;
}
