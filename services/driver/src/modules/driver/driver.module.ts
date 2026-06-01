import { Module } from "@nestjs/common";
import { DriverService } from "@driver/driver/application/services/driver.service";
import { DRIVER_REPOSITORY } from "@driver/driver/domain/repositories/driver-repository.interface";
import { DrizzleDriverRepository } from "@driver/driver/infra/repositories/drizzle-driver.repository";
import { DriversController } from "@driver/driver/infra/controllers/drivers.controller";

@Module({
  controllers: [DriversController],
  providers: [
    DriverService,
    DrizzleDriverRepository,
    { provide: DRIVER_REPOSITORY, useExisting: DrizzleDriverRepository },
  ],
})
export class DriverModule {}
