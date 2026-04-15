import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Pet } from './entities/pet.entity';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';

@Injectable()
export class PetService {
  constructor(
    @InjectRepository(Pet)
    private readonly petRepository: Repository<Pet>,
  ) {}

  findByUser(userId: string): Promise<Pet[]> {
    return this.petRepository.find({ where: { userId } });
  }

  async findById(id: string): Promise<Pet> {
    const pet = await this.petRepository.findOne({ where: { id } });
    if (!pet) {
      throw new NotFoundException(`Pet com id "${id}" não encontrado`);
    }
    return pet;
  }

  create(userId: string, dto: CreatePetDto): Promise<Pet> {
    const pet = this.petRepository.create({ ...dto, userId });
    return this.petRepository.save(pet);
  }

  async update(id: string, dto: UpdatePetDto): Promise<Pet> {
    const pet = await this.findById(id);
    Object.assign(pet, dto);
    return this.petRepository.save(pet);
  }

  async remove(id: string): Promise<void> {
    const pet = await this.findById(id);
    await this.petRepository.remove(pet);
  }
}
