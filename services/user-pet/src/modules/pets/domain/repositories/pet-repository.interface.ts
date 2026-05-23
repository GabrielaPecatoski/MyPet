import type { Pet } from "@pets/pets/domain/models/pet.entity";
import type { PaginationParams } from "@shared/infra/hateoas";

export const PET_REPOSITORY = Symbol("PET_REPOSITORY");

export interface PetRepository {
  create(pet: Pet): Promise<Pet>;
  update(pet: Pet): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Pet | null>;
  findByUserId(userId: string): Promise<Pet[]>;
  findAllPaginated(params: PaginationParams): Promise<{ rows: Pet[]; total: number }>;
}
