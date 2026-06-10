import { Driver } from "@driver/driver/domain/models/driver.entity";
import type { DriverRepository } from "@driver/driver/domain/repositories/driver-repository.interface";
import { driversSchema } from "@driver/driver/infra/database/schemas/driver.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq, isNull } from "drizzle-orm";

@Injectable()
export class DrizzleDriverRepository implements DriverRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(driver: Driver): Promise<Driver> {
    const [row] = await this.drizzleService.db
      .insert(driversSchema)
      .values({
        establishmentId: driver.establishmentId ?? null,
        name: driver.name,
        phone: driver.phone,
        cpf: driver.cpf,
        cnh: driver.cnh,
        vehicleType: driver.vehicleType,
        vehicleModel: driver.vehicleModel,
        vehiclePlate: driver.vehiclePlate,
        status: driver.status,
        createdAt: new Date(),
        updatedAt: new Date(),
      })
      .returning();
    return Driver.restore(row)!;
  }

  async findAll(): Promise<Driver[]> {
    const rows = await this.drizzleService.db.select().from(driversSchema);
    return rows.map((r) => Driver.restore(r)!);
  }

  async findByStatus(status: string): Promise<Driver[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(driversSchema)
      .where(eq(driversSchema.status, status));
    return rows.map((r) => Driver.restore(r)!);
  }

  async findById(id: string): Promise<Driver | null> {
    const [row] = await this.drizzleService.db
      .select()
      .from(driversSchema)
      .where(eq(driversSchema.id, id))
      .limit(1);
    return Driver.restore(row);
  }

  async findByCpf(cpf: string): Promise<Driver | null> {
    const [row] = await this.drizzleService.db
      .select()
      .from(driversSchema)
      .where(eq(driversSchema.cpf, cpf))
      .limit(1);
    return Driver.restore(row);
  }

  async findByEstablishment(establishmentId: string): Promise<Driver[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(driversSchema)
      .where(eq(driversSchema.establishmentId, establishmentId));
    return rows.map((r) => Driver.restore(r)!);
  }

  async findUnassociated(): Promise<Driver[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(driversSchema)
      .where(isNull(driversSchema.establishmentId));
    return rows.map((r) => Driver.restore(r)!);
  }

  async update(driver: Driver): Promise<void> {
    await this.drizzleService.db
      .update(driversSchema)
      .set({
        establishmentId: driver.establishmentId ?? null,
        status: driver.status,
        updatedAt: new Date(),
      })
      .where(eq(driversSchema.id, driver.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(driversSchema).where(eq(driversSchema.id, id));
  }
}
