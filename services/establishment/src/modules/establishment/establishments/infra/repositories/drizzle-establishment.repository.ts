import { Establishment } from "@estab/establishments/domain/models/establishment.entity";
import type { EstablishmentRepository } from "@estab/establishments/domain/repositories/establishment-repository.interface";
import { establishmentsSchema } from "@estab/establishments/infra/database/schemas/establishment.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import type { PaginationParams } from "@shared/infra/hateoas";
import { eq, ilike, or, sql } from "drizzle-orm";

@Injectable()
export class DrizzleEstablishmentRepository implements EstablishmentRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(e: Establishment): Promise<void> {
    await this.drizzleService.db.insert(establishmentsSchema).values({
      ownerId: e.ownerId,
      name: e.name,
      description: e.description,
      address: e.address,
      city: e.city,
      phone: e.phone,
      type: e.type,
      rating: e.rating,
      reviewCount: e.reviewCount,
      imageUrl: e.imageUrl,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
  }

  async update(e: Establishment): Promise<void> {
    await this.drizzleService.db
      .update(establishmentsSchema)
      .set({
        name: e.name,
        description: e.description,
        address: e.address,
        city: e.city,
        phone: e.phone,
        type: e.type,
        rating: e.rating,
        reviewCount: e.reviewCount,
        imageUrl: e.imageUrl,
        updatedAt: new Date(),
      })
      .where(eq(establishmentsSchema.id, e.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(establishmentsSchema).where(eq(establishmentsSchema.id, id));
  }

  async findById(id: string): Promise<Establishment | null> {
    const result = await this.drizzleService.db
      .select()
      .from(establishmentsSchema)
      .where(eq(establishmentsSchema.id, id))
      .limit(1);
    return Establishment.restore(result[0]);
  }

  async findByOwnerId(ownerId: string): Promise<Establishment[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(establishmentsSchema)
      .where(eq(establishmentsSchema.ownerId, ownerId));
    return rows.map((r) => Establishment.restore(r)!);
  }

  async findAll(search?: string): Promise<Establishment[]> {
    const query = this.drizzleService.db.select().from(establishmentsSchema);
    if (search) {
      const rows = await query.where(
        or(ilike(establishmentsSchema.name, `%${search}%`), ilike(establishmentsSchema.city, `%${search}%`)),
      );
      return rows.map((r) => Establishment.restore(r)!);
    }
    const rows = await query;
    return rows.map((r) => Establishment.restore(r)!);
  }

  async findAllPaginated(params: PaginationParams, search?: string): Promise<{ rows: Establishment[]; total: number }> {
    const { page, limit } = params;
    const offset = (page - 1) * limit;

    const whereClause = search
      ? or(ilike(establishmentsSchema.name, `%${search}%`), ilike(establishmentsSchema.city, `%${search}%`))
      : undefined;

    const [rows, [countResult]] = await Promise.all([
      whereClause
        ? this.drizzleService.db.select().from(establishmentsSchema).where(whereClause).limit(limit).offset(offset)
        : this.drizzleService.db.select().from(establishmentsSchema).limit(limit).offset(offset),
      whereClause
        ? this.drizzleService.db.select({ count: sql<number>`count(*)::int` }).from(establishmentsSchema).where(whereClause)
        : this.drizzleService.db.select({ count: sql<number>`count(*)::int` }).from(establishmentsSchema),
    ]);

    return {
      rows: rows.map((r) => Establishment.restore(r)!),
      total: countResult.count,
    };
  }
}
