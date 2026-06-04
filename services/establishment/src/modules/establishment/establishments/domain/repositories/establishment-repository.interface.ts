import type { Establishment } from "@estab/establishments/domain/models/establishment.entity";
import type { PaginationParams } from "@shared/infra/hateoas";

export const ESTABLISHMENT_REPOSITORY = Symbol("ESTABLISHMENT_REPOSITORY");

export interface EstablishmentAdminItem {
  id: string;
  ownerId: string;
  name: string;
  description: string;
  address: string;
  city: string;
  phone: string;
  type: string;
  rating: number;
  reviewCount: number;
  imageUrl: string | null | undefined;
  servicesCount: number;
}

export interface EstablishmentRepository {
  create(establishment: Establishment): Promise<Establishment>;
  update(establishment: Establishment): Promise<void>;
  updateRating(id: string, rating: number, reviewCount: number): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Establishment | null>;
  findByOwnerId(ownerId: string): Promise<Establishment[]>;
  findAll(search?: string): Promise<(Establishment & { serviceCount: number })[]>;
  findAllPaginated(params: PaginationParams, search?: string): Promise<{ rows: Establishment[]; total: number }>;
  findAllAdmin(): Promise<EstablishmentAdminItem[]>;
  findByEmergency(): Promise<(Establishment & { serviceCount: number })[]>;
}
