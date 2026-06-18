import { Product } from "@market/products/domain/models/product.entity";
import type { ProductRepository } from "@market/products/domain/repositories/product-repository.interface";
import { productsSchema } from "@market/products/infra/database/schemas/product.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import type { PaginationParams } from "@shared/infra/hateoas";
import { and, eq, ilike, or, sql } from "drizzle-orm";

@Injectable()
export class DrizzleProductRepository implements ProductRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(p: Product): Promise<Product> {
    const [row] = await this.drizzleService.db
      .insert(productsSchema)
      .values({
        establishmentId: p.establishmentId,
        name: p.name,
        brand: p.brand,
        price: p.price,
        unit: p.unit,
        category: p.category,
        description: p.description,
        stock: p.stock,
        imageUrl: p.imageUrl,
        active: p.active,
        createdAt: new Date(),
      })
      .returning();
    return Product.restore(row)!;
  }

  async update(p: Product): Promise<void> {
    await this.drizzleService.db
      .update(productsSchema)
      .set({
        name: p.name,
        brand: p.brand,
        price: p.price,
        unit: p.unit,
        category: p.category,
        description: p.description,
        stock: p.stock,
        imageUrl: p.imageUrl,
        active: p.active,
      })
      .where(eq(productsSchema.id, p.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db
      .delete(productsSchema)
      .where(eq(productsSchema.id, id));
  }

  async findById(id: string): Promise<Product | null> {
    const result = await this.drizzleService.db
      .select()
      .from(productsSchema)
      .where(eq(productsSchema.id, id))
      .limit(1);
    return Product.restore(result[0]);
  }

  async findAll(search?: string): Promise<Product[]> {
    const baseQuery = this.drizzleService.db.select().from(productsSchema);
    const rows = search
      ? await baseQuery.where(
          and(
            eq(productsSchema.active, true),
            or(
              ilike(productsSchema.name, `%${search}%`),
              ilike(productsSchema.category, `%${search}%`),
              ilike(productsSchema.brand, `%${search}%`),
            ),
          ),
        )
      : await baseQuery.where(eq(productsSchema.active, true));
    return rows.map((r) => Product.restore(r)!);
  }

  async findByEstablishment(establishmentId: string): Promise<Product[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(productsSchema)
      .where(eq(productsSchema.establishmentId, establishmentId));
    return rows.map((r) => Product.restore(r)!);
  }

  async findAllPaginated(
    params: PaginationParams,
    search?: string,
  ): Promise<{ rows: Product[]; total: number }> {
    const { page, limit } = params;
    const offset = (page - 1) * limit;
    const whereClause = search
      ? and(
          eq(productsSchema.active, true),
          or(
            ilike(productsSchema.name, `%${search}%`),
            ilike(productsSchema.category, `%${search}%`),
          ),
        )
      : eq(productsSchema.active, true);

    const [rows, [countResult]] = await Promise.all([
      this.drizzleService.db
        .select()
        .from(productsSchema)
        .where(whereClause)
        .limit(limit)
        .offset(offset),
      this.drizzleService.db
        .select({ count: sql<number>`count(*)::int` })
        .from(productsSchema)
        .where(whereClause),
    ]);

    return {
      rows: rows.map((r) => Product.restore(r)!),
      total: countResult.count,
    };
  }
}
