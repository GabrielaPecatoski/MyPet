import { Module } from "@nestjs/common";
import { PetService } from "@pets/pets/application/services/pet.service";
import { PET_REPOSITORY } from "@pets/pets/domain/repositories/pet-repository.interface";
import { PetsController } from "@pets/pets/infra/controllers/pets.controller";
import { DrizzlePetRepository } from "@pets/pets/infra/repositories/drizzle-pet.repository";

@Module({
  controllers: [PetsController],
  providers: [
    PetService,
    DrizzlePetRepository,
    {
      provide: PET_REPOSITORY,
      useExisting: DrizzlePetRepository,
    },
  ],
})
export class PetsModule {}
