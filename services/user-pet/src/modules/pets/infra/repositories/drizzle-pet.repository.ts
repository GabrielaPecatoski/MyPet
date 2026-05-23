import { Pet } from "@pets/pets/domain/models/pet.entity";
import type { PetRepository } from "@pets/pets/domain/repositories/pet-repository.interface";
import { petsSchema } from "@pets/pets/infra/database/schemas/pet.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import type { PaginationParams } from "@shared/infra/hateoas";
import { eq, sql } from "drizzle-orm";

@Injectable()
export class DrizzlePetRepository implements PetRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(pet: Pet): Promise<Pet> {
    const [row] = await this.drizzleService.db
      .insert(petsSchema)
      .values({
        userId: pet.userId,
        name: pet.name,
        type: pet.type,
        breed: pet.breed,
        age: pet.age,
        weight: pet.weight,
        imageUrl: pet.imageUrl,
        notes: pet.notes,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();
    return Pet.restore(row)!;
  }

  async update(pet: Pet): Promise<void> {
    await this.drizzleService.db
      .update(petsSchema)
      .set({
        name: pet.name,
        type: pet.type,
        breed: pet.breed,
        age: pet.age,
        weight: pet.weight,
        imageUrl: pet.imageUrl,
        notes: pet.notes,
        updatedAt: new Date(),
      })
      .where(eq(petsSchema.id, pet.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(petsSchema).where(eq(petsSchema.id, id));
  }

  async findById(id: string): Promise<Pet | null> {
    const result = await this.drizzleService.db
      .select()
      .from(petsSchema)
      .where(eq(petsSchema.id, id))
      .limit(1);
    return Pet.restore(result[0]);
  }

  async findByUserId(userId: string): Promise<Pet[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(petsSchema)
      .where(eq(petsSchema.userId, userId));
    return rows.map((r) => Pet.restore(r)!);
  }

  async findAllPaginated(params: PaginationParams): Promise<{ rows: Pet[]; total: number }> {
    const { page, limit } = params;
    const offset = (page - 1) * limit;

    const [rows, [countResult]] = await Promise.all([
      this.drizzleService.db.select().from(petsSchema).limit(limit).offset(offset),
      this.drizzleService.db.select({ count: sql<number>`count(*)::int` }).from(petsSchema),
    ]);

    return {
      rows: rows.map((r) => Pet.restore(r)!),
      total: countResult.count,
    };
  }
}
