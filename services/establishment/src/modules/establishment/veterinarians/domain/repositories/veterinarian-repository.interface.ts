import type { Veterinarian } from '@estab/veterinarians/domain/models/veterinarian.entity';

export const VETERINARIAN_REPOSITORY = Symbol('VETERINARIAN_REPOSITORY');

export interface VeterinarianRepository {
  create(vet: Veterinarian): Promise<Veterinarian>;
  findAll(): Promise<Veterinarian[]>;
  findById(id: string): Promise<Veterinarian | null>;
  findByCpf(cpf: string): Promise<Veterinarian | null>;
  findByEstablishment(establishmentId: string): Promise<Veterinarian[]>;
  findUnassociated(): Promise<Veterinarian[]>;
  update(vet: Veterinarian): Promise<void>;
  delete(id: string): Promise<void>;
}
