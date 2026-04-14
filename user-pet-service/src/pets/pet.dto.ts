import { PetType } from '../pet.entity';

export class CreatePetDto {
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
}

export class UpdatePetDto {
  name?: string;
  breed?: string;
  weight?: number;
  color?: string;
  microchipId?: string;
  profileImage?: string;
  bio?: string;
}
