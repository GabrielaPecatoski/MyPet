import { v4 as uuidv4 } from 'uuid';

export enum PetType {
  DOG = 'DOG',
  CAT = 'CAT',
  BIRD = 'BIRD',
  RABBIT = 'RABBIT',
  HAMSTER = 'HAMSTER',
  FISH = 'FISH',
  REPTILE = 'REPTILE',
  OTHER = 'OTHER',
}

export class Pet {
  id: string;
  userId: string;
  name: string;
  type: PetType;
  breed: string;
  birthDate: Date;
  weight?: number;
  color?: string;
  microchipId?: string;
  profileImage?: string;
  bio?: string;
  isActive: boolean;
  createdAt: Date;
  updatedAt: Date;

  constructor(
    userId: string,
    name: string,
    type: PetType,
    breed: string,
    birthDate: Date,
  ) {
    this.id = uuidv4();
    this.userId = userId;
    this.name = name;
    this.type = type;
    this.breed = breed;
    this.birthDate = birthDate;
    this.isActive = true;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }
}
