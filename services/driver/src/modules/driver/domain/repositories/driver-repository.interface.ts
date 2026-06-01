import type { Driver } from "@driver/driver/domain/models/driver.entity";

export const DRIVER_REPOSITORY = Symbol("DRIVER_REPOSITORY");

export interface DriverRepository {
  create(driver: Driver): Promise<Driver>;
  findAll(): Promise<Driver[]>;
  findById(id: string): Promise<Driver | null>;
  findByCpf(cpf: string): Promise<Driver | null>;
  findByEstablishment(establishmentId: string): Promise<Driver[]>;
  findUnassociated(): Promise<Driver[]>;
  update(driver: Driver): Promise<void>;
  delete(id: string): Promise<void>;
}
