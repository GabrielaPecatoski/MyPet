// @ts-ignore
import { Injectable } from '@nestjs/common';
// @ts-ignore
import { Pet, PetType } from './pet.entity';
// @ts-ignore
import { CreatePetDto, UpdatePetDto } from './pet.dto';

@Injectable()
export class PetsService {
  private pets: Pet[] = [];

  /**
   * Validates pet name
   * @param name Pet name to validate
   * @returns true if valid
   */
  private validateName(name: string): boolean {
    return !!(name && name.trim().length >= 2 && name.trim().length <= 100);
  }

  /**
   * Validates pet type
   * @param type Pet type to validate
   * @returns true if valid
   */
  private validateType(type: string): boolean {
    return Object.values(PetType).includes(type as PetType);
  }

  /**
   * Validates pet breed
   * @param breed Pet breed to validate
   * @returns true if valid
   */
  private validateBreed(breed: string): boolean {
    return !!(breed && breed.trim().length >= 2 && breed.trim().length <= 100);
  }

  /**
   * Validates birth date (pet must be valid age)
   * @param birthDate Pet birth date
   * @returns true if valid
   */
  private validateBirthDate(birthDate: Date): boolean {
    const birth = new Date(birthDate);
    const today = new Date();
    const age = today.getFullYear() - birth.getFullYear();
    return age >= 0 && age <= 50;
  }

  /**
   * Creates a new pet
   * @param createPetDto Pet creation DTO
   * @returns Created pet
   * @throws Error if validation fails
   */
  async create(createPetDto: CreatePetDto): Promise<Pet> {
    if (!createPetDto.userId || !createPetDto.userId.trim()) {
      throw new Error('UserId is required');
    }

    if (!this.validateName(createPetDto.name)) {
      throw new Error('Pet name must be between 2 and 100 characters');
    }

    if (!this.validateType(createPetDto.type)) {
      throw new Error('Invalid pet type');
    }

    if (!this.validateBreed(createPetDto.breed)) {
      throw new Error('Breed must be between 2 and 100 characters');
    }

    if (!this.validateBirthDate(createPetDto.birthDate)) {
      throw new Error('Birth date must be valid (pet age between 0 and 50 years)');
    }

    if (createPetDto.weight !== undefined && (createPetDto.weight < 0.1 || createPetDto.weight > 500)) {
      throw new Error('Weight must be between 0.1 and 500 kg');
    }

    const pet = new Pet(
      createPetDto.userId,
      createPetDto.name.trim(),
      createPetDto.type,
      createPetDto.breed.trim(),
      new Date(createPetDto.birthDate),
    );

    if (createPetDto.weight !== undefined) pet.weight = createPetDto.weight;
    if (createPetDto.color) pet.color = createPetDto.color.trim();
    if (createPetDto.microchipId) pet.microchipId = createPetDto.microchipId.trim();
    if (createPetDto.profileImage) pet.profileImage = createPetDto.profileImage.trim();
    if (createPetDto.bio) pet.bio = createPetDto.bio.trim();

    this.pets.push(pet);
    return pet;
  }

  /**
   * Finds all pets by userId
   * @param userId User ID
   * @param skip Pagination skip
   * @param take Pagination take
   * @returns Array of pets
   */
  async findByUserId(userId: string, skip: number = 0, take: number = 10): Promise<Pet[]> {
    if (!userId || !userId.trim()) {
      throw new Error('UserId is required');
    }

    skip = Math.max(0, skip || 0);
    take = Math.min(100, Math.max(1, take || 10));

    return this.pets
      .filter((p) => p.userId === userId && p.isActive)
      .slice(skip, skip + take);
  }

  /**
   * Gets pet by ID
   * @param petId Pet ID
   * @returns Pet or null
   */
  async findById(petId: string): Promise<Pet | null> {
    if (!petId || !petId.trim()) {
      throw new Error('PetId is required');
    }

    return this.pets.find((p) => p.id === petId && p.isActive) || null;
  }

  /**
   * Updates pet information
   * @param petId Pet ID
   * @param updatePetDto Update DTO
   * @returns Updated pet
   * @throws Error if pet not found
   */
  async update(petId: string, updatePetDto: UpdatePetDto): Promise<Pet> {
    const pet = await this.findById(petId);

    if (!pet) {
      throw new Error('Pet not found');
    }

    if (updatePetDto.name !== undefined) {
      if (!this.validateName(updatePetDto.name)) {
        throw new Error('Pet name must be between 2 and 100 characters');
      }
      pet.name = updatePetDto.name.trim();
    }

    if (updatePetDto.breed !== undefined) {
      if (!this.validateBreed(updatePetDto.breed)) {
        throw new Error('Breed must be between 2 and 100 characters');
      }
      pet.breed = updatePetDto.breed.trim();
    }

    if (updatePetDto.weight !== undefined) {
      if (updatePetDto.weight < 0.1 || updatePetDto.weight > 500) {
        throw new Error('Weight must be between 0.1 and 500 kg');
      }
      pet.weight = updatePetDto.weight;
    }

    if (updatePetDto.color !== undefined) pet.color = updatePetDto.color.trim();
    if (updatePetDto.microchipId !== undefined) pet.microchipId = updatePetDto.microchipId.trim();
    if (updatePetDto.profileImage !== undefined) pet.profileImage = updatePetDto.profileImage.trim();
    if (updatePetDto.bio !== undefined) pet.bio = updatePetDto.bio.trim();

    pet.updatedAt = new Date();
    return pet;
  }

  /**
   * Gets pet statistics for a user
   * @param userId User ID
   * @returns Pet statistics
   */
  async getPetStats(userId: string): Promise<{
    totalPets: number;
    byType: Record<string, number>;
  }> {
    if (!userId || !userId.trim()) {
      throw new Error('UserId is required');
    }

    const userPets = this.pets.filter((p) => p.userId === userId && p.isActive);
    const byType: Record<string, number> = {};

    Object.values(PetType).forEach((type) => {
      byType[type] = userPets.filter((p) => p.type === type).length;
    });

    return {
      totalPets: userPets.length,
      byType,
    };
  }

  /**
   * Deactivates a pet (soft delete)
   * @param petId Pet ID
   * @returns Deactivated pet
   */
  async deactivate(petId: string): Promise<Pet> {
    const pet = await this.findById(petId);

    if (!pet) {
      throw new Error('Pet not found');
    }

    pet.isActive = false;
    pet.updatedAt = new Date();
    return pet;
  }
}
