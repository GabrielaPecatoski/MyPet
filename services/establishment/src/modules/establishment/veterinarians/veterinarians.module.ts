import { Module } from '@nestjs/common';
import { VeterinarianService } from '@estab/veterinarians/application/services/veterinarian.service';
import { VETERINARIAN_REPOSITORY } from '@estab/veterinarians/domain/repositories/veterinarian-repository.interface';
import { DrizzleVeterinarianRepository } from '@estab/veterinarians/infra/repositories/drizzle-veterinarian.repository';
import { VeterinariansController } from '@estab/veterinarians/infra/controllers/veterinarians.controller';

@Module({
  controllers: [VeterinariansController],
  providers: [
    VeterinarianService,
    DrizzleVeterinarianRepository,
    { provide: VETERINARIAN_REPOSITORY, useExisting: DrizzleVeterinarianRepository },
  ],
})
export class VeterinariansModule {}
