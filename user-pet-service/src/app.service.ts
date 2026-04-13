import { Injectable, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';

export interface Pet {
  id: string;
  userId: string;
  name: string;
  type: string;
  breed: string;
  age: number;
  weight?: number;
  imageUrl?: string;
  notes?: string;
}

@Injectable()
export class AppService {
  private pets: Pet[] = [
    { id: 'pet-001', userId: 'cliente-001', name: 'Rex', type: 'Cachorro', breed: 'Golden Retriever', age: 3, weight: 28 },
    { id: 'pet-002', userId: 'cliente-001', name: 'Luna', type: 'Gato', breed: 'Siamês', age: 2, weight: 4 },
  ];

  findByUser(userId: string): Pet[] {
    return this.pets.filter((p) => p.userId === userId);
  }

  findById(id: string): Pet {
    const pet = this.pets.find((p) => p.id === id);
    if (!pet) throw new NotFoundException('Pet não encontrado');
    return pet;
  }

  create(userId: string, data: Omit<Pet, 'id' | 'userId'>): Pet {
    const pet: Pet = { ...data, id: crypto.randomUUID(), userId };
    this.pets.push(pet);
    return pet;
  }

  update(id: string, data: Partial<Pet>): Pet {
    const idx = this.pets.findIndex((p) => p.id === id);
    if (idx === -1) throw new NotFoundException('Pet não encontrado');
    this.pets[idx] = { ...this.pets[idx], ...data };
    return this.pets[idx];
  }

  remove(id: string): void {
    const idx = this.pets.findIndex((p) => p.id === id);
    if (idx === -1) throw new NotFoundException('Pet não encontrado');
    this.pets.splice(idx, 1);
  }
}
