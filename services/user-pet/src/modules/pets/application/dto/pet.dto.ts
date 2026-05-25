import type { Pet } from "@pets/pets/domain/models/pet.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class PetDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() userId: string;
  @ApiProperty() name: string;
  @ApiProperty() type: string;
  @ApiProperty() breed: string;
  @ApiProperty() age: number;
  @ApiProperty() weight: number;
  @ApiPropertyOptional() imageUrl?: string;
  @ApiPropertyOptional() notes?: string;
  @ApiProperty() createdAt: Date | undefined;

  private constructor(
    id: string | undefined,
    userId: string,
    name: string,
    type: string,
    breed: string,
    age: number,
    weight: number,
    imageUrl: string | undefined,
    notes: string | undefined,
    createdAt: Date | undefined,
  ) {
    this.id = id;
    this.userId = userId;
    this.name = name;
    this.type = type;
    this.breed = breed;
    this.age = age;
    this.weight = weight;
    this.imageUrl = imageUrl;
    this.notes = notes;
    this.createdAt = createdAt;
  }

  static fromPet(pet: Pet | null): PetDto | null {
    if (!pet) return null;
    return new PetDto(
      pet.id,
      pet.userId,
      pet.name,
      pet.type,
      pet.breed,
      pet.age,
      pet.weight,
      pet.imageUrl,
      pet.notes,
      pet.createdAt,
    );
  }
}
