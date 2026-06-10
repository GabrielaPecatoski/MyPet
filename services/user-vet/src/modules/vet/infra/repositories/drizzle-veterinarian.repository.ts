import { Veterinarian } from '@vet/vet/domain/models/veterinarian.entity';
import type { VeterinarianRepository } from '@vet/vet/domain/repositories/veterinarian-repository.interface';
import { veterinariansSchema } from '@vet/vet/infra/database/schemas/veterinarian.schema';
import { Injectable } from '@nestjs/common';
import { DrizzleService } from '@shared/infra/database/drizzle.service';
import { and, eq, isNull } from 'drizzle-orm';

@Injectable()
export class DrizzleVeterinarianRepository implements VeterinarianRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(vet: Veterinarian): Promise<Veterinarian> {
    const [row] = await this.drizzleService.db
      .insert(veterinariansSchema)
      .values({
        establishmentId: vet.establishmentId ?? null,
        name: vet.name,
        phone: vet.phone,
        cpf: vet.cpf,
        crmv: vet.crmv,
        especialidade: vet.especialidade ?? null,
        status: vet.status,
        disponivel: vet.disponivel,
        atendeDomicilio: vet.atendeDomicilio,
        atende24h: vet.atende24h,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();
    return Veterinarian.restore(row)!;
  }

  async findAll(): Promise<Veterinarian[]> {
    const rows = await this.drizzleService.db.select().from(veterinariansSchema);
    return rows.map((r) => Veterinarian.restore(r)!);
  }

  async findByStatus(status: string): Promise<Veterinarian[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(veterinariansSchema)
      .where(eq(veterinariansSchema.status, status));
    return rows.map((r) => Veterinarian.restore(r)!);
  }

  async findAvailable(): Promise<Veterinarian[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(veterinariansSchema)
      .where(and(eq(veterinariansSchema.status, 'ATIVO'), eq(veterinariansSchema.disponivel, true)));
    return rows.map((r) => Veterinarian.restore(r)!);
  }

  async findById(id: string): Promise<Veterinarian | null> {
    const [row] = await this.drizzleService.db
      .select()
      .from(veterinariansSchema)
      .where(eq(veterinariansSchema.id, id))
      .limit(1);
    return Veterinarian.restore(row);
  }

  async findByCpf(cpf: string): Promise<Veterinarian | null> {
    const [row] = await this.drizzleService.db
      .select()
      .from(veterinariansSchema)
      .where(eq(veterinariansSchema.cpf, cpf))
      .limit(1);
    return Veterinarian.restore(row);
  }

  async findByEstablishment(establishmentId: string): Promise<Veterinarian[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(veterinariansSchema)
      .where(eq(veterinariansSchema.establishmentId, establishmentId));
    return rows.map((r) => Veterinarian.restore(r)!);
  }

  async findUnassociated(): Promise<Veterinarian[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(veterinariansSchema)
      .where(isNull(veterinariansSchema.establishmentId));
    return rows.map((r) => Veterinarian.restore(r)!);
  }

  async update(vet: Veterinarian): Promise<void> {
    await this.drizzleService.db
      .update(veterinariansSchema)
      .set({
        establishmentId: vet.establishmentId ?? null,
        especialidade: vet.especialidade ?? null,
        status: vet.status,
        disponivel: vet.disponivel,
        atendeDomicilio: vet.atendeDomicilio,
        atende24h: vet.atende24h,
        updatedAt: new Date(),
      })
      .where(eq(veterinariansSchema.id, vet.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db
      .delete(veterinariansSchema)
      .where(eq(veterinariansSchema.id, id));
  }
}
