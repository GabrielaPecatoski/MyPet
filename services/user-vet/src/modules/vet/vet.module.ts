import { Module } from '@nestjs/common';
import { VeterinarianService } from '@vet/vet/application/services/veterinarian.service';
import { VETERINARIAN_REPOSITORY } from '@vet/vet/domain/repositories/veterinarian-repository.interface';
import { DrizzleVeterinarianRepository } from '@vet/vet/infra/repositories/drizzle-veterinarian.repository';
import { VetEmergencyCallsRepository } from '@vet/vet/infra/repositories/vet-emergency-calls.repository';
import { VeterinariansController } from '@vet/vet/infra/controllers/veterinarians.controller';

@Module({
  controllers: [VeterinariansController],
  providers: [
    VeterinarianService,
    DrizzleVeterinarianRepository,
    VetEmergencyCallsRepository,
    { provide: VETERINARIAN_REPOSITORY, useExisting: DrizzleVeterinarianRepository },
  ],
})
export class VetModule {}
