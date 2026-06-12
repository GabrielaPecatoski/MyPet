import { DriverService } from "@driver/driver/application/services/driver.service";
import { DRIVER_REPOSITORY } from "@driver/driver/domain/repositories/driver-repository.interface";
import { DriversController } from "@driver/driver/infra/controllers/drivers.controller";
import { DrizzleDriverRepository } from "@driver/driver/infra/repositories/drizzle-driver.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [DriversController],
  providers: [
    DriverService,
    DrizzleDriverRepository,
    { provide: DRIVER_REPOSITORY, useExisting: DrizzleDriverRepository },
  ],
})
export class DriverModule {}
