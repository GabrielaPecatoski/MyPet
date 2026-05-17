import { CreatePetDto } from "@pets/pets/application/dto/create-pet.dto";
import { PetDto } from "@pets/pets/application/dto/pet.dto";
import { UpdatePetDto } from "@pets/pets/application/dto/update-pet.dto";
import { Pet } from "@pets/pets/domain/models/pet.entity";
import {
  PET_REPOSITORY,
  type PetRepository,
} from "@pets/pets/domain/repositories/pet-repository.interface";
import {
  Inject,
  Injectable,
  NotFoundException,
} from "@nestjs/common";
import type { PaginatedResult, PaginationParams } from "@shared/infra/hateoas";

@Injectable()
export class PetService {
  constructor(
    @Inject(PET_REPOSITORY)
    private readonly petRepository: PetRepository,
  ) {}

  async create(userId: string, dto: CreatePetDto): Promise<void> {
    const pet = Pet.restore({
      userId,
      name: dto.name,
      type: dto.type,
      breed: dto.breed,
      age: dto.age,
      weight: dto.weight,
      imageUrl: dto.imageUrl,
      notes: dto.notes,
    })!;
    await this.petRepository.create(pet);
  }

  async findByUserId(userId: string): Promise<PetDto[]> {
    const pets = await this.petRepository.findByUserId(userId);
    return pets.map((p) => PetDto.fromPet(p)!);
  }

  async findById(id: string): Promise<PetDto | null> {
    const pet = await this.petRepository.findById(id);
    return PetDto.fromPet(pet);
  }

  async listPaginated(params: PaginationParams): Promise<PaginatedResult<PetDto>> {
    const { rows, total } = await this.petRepository.findAllPaginated(params);
    return {
      data: rows.map((p) => PetDto.fromPet(p)!),
      total,
      page: params.page,
      limit: params.limit,
    };
  }

  async update(id: string, dto: UpdatePetDto): Promise<void> {
    const pet = await this.petRepository.findById(id);
    if (!pet) throw new NotFoundException("Pet não encontrado");
    if (dto.name) pet.withName(dto.name);
    if (dto.type) pet.withType(dto.type);
    if (dto.breed) pet.withBreed(dto.breed);
    if (dto.age !== undefined) pet.withAge(dto.age);
    if (dto.weight !== undefined) pet.withWeight(dto.weight);
    if (dto.imageUrl !== undefined) pet.withImageUrl(dto.imageUrl);
    if (dto.notes !== undefined) pet.withNotes(dto.notes);
    await this.petRepository.update(pet);
  }

  async remove(id: string): Promise<void> {
    const pet = await this.petRepository.findById(id);
    if (!pet) throw new NotFoundException("Pet não encontrado");
    await this.petRepository.delete(id);
  }
}
