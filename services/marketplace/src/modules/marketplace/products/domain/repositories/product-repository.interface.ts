import type { Product } from "@market/products/domain/models/product.entity";
import type { PaginationParams } from "@shared/infra/hateoas";

export const PRODUCT_REPOSITORY = Symbol("PRODUCT_REPOSITORY");

export interface ProductRepository {
  create(product: Product): Promise<Product>;
  update(product: Product): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<Product | null>;
  findAll(search?: string): Promise<Product[]>;
  findByEstablishment(establishmentId: string): Promise<Product[]>;
  findAllPaginated(
    params: PaginationParams,
    search?: string,
  ): Promise<{ rows: Product[]; total: number }>;
}
