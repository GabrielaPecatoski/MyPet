import { Establishment } from "@estab/establishments/domain/models/establishment.entity";
import type { EstablishmentAdminItem, EstablishmentRepository } from "@estab/establishments/domain/repositories/establishment-repository.interface";
import { establishmentsSchema } from "@estab/establishments/infra/database/schemas/establishment.schema";
import { estabServicesSchema } from "@estab/services/infra/database/schemas/estab-service.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import type { PaginationParams } from "@shared/infra/hateoas";
import { eq, ilike, or, sql } from "drizzle-orm";

@Injectable()
export class DrizzleEstablishmentRepository implements EstablishmentRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(e: Establishment): Promise<Establishment> {
    const [row] = await this.drizzleService.db
      .insert(establishmentsSchema)
      .values({
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
      })
      .returning();
    return Establishment.restore(row)!;
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

  async updateRating(id: string, rating: number, reviewCount: number): Promise<void> {
    await this.drizzleService.db
      .update(establishmentsSchema)
      .set({ rating, reviewCount, updatedAt: new Date() })
      .where(eq(establishmentsSchema.id, id));
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

  async findAll(search?: string): Promise<(Establishment & { serviceCount: number })[]> {
    const baseQuery = this.drizzleService.db
      .select({
        id: establishmentsSchema.id,
        ownerId: establishmentsSchema.ownerId,
        name: establishmentsSchema.name,
        description: establishmentsSchema.description,
        address: establishmentsSchema.address,
        city: establishmentsSchema.city,
        phone: establishmentsSchema.phone,
        type: establishmentsSchema.type,
        rating: establishmentsSchema.rating,
        reviewCount: establishmentsSchema.reviewCount,
        imageUrl: establishmentsSchema.imageUrl,
        createdAt: establishmentsSchema.createdAt,
        updatedAt: establishmentsSchema.updatedAt,
        serviceCount: sql<number>`count(${estabServicesSchema.id})::int`,
      })
      .from(establishmentsSchema)
      .leftJoin(estabServicesSchema, eq(estabServicesSchema.establishmentId, establishmentsSchema.id))
      .groupBy(establishmentsSchema.id);

    const rows = search
      ? await baseQuery.where(
          or(ilike(establishmentsSchema.name, `%${search}%`), ilike(establishmentsSchema.city, `%${search}%`)),
        )
      : await baseQuery;

    return rows.map((r) => Object.assign(Establishment.restore(r)!, { serviceCount: r.serviceCount }));
  }

  async findAllAdmin(): Promise<EstablishmentAdminItem[]> {
    const rows = await this.drizzleService.db
      .select({
        id: establishmentsSchema.id,
        ownerId: establishmentsSchema.ownerId,
        name: establishmentsSchema.name,
        description: establishmentsSchema.description,
        address: establishmentsSchema.address,
        city: establishmentsSchema.city,
        phone: establishmentsSchema.phone,
        type: establishmentsSchema.type,
        rating: establishmentsSchema.rating,
        reviewCount: establishmentsSchema.reviewCount,
        imageUrl: establishmentsSchema.imageUrl,
        servicesCount: sql<number>`count(${estabServicesSchema.id})::int`,
      })
      .from(establishmentsSchema)
      .leftJoin(estabServicesSchema, eq(estabServicesSchema.establishmentId, establishmentsSchema.id))
      .groupBy(establishmentsSchema.id);
    return rows;
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
