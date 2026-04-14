export enum EstablishmentType {
  PET_SHOP = 'PET_SHOP',
  VET_CLINIC = 'VET_CLINIC',
  GROOMING = 'GROOMING',
  HOTEL = 'HOTEL',
  TRAINING = 'TRAINING',
  OTHER = 'OTHER',
}

export class EstablishmentProfile {
  id: string;
  ownerId: string;
  name: string;
  email: string;
  phone: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  cnpj: string;
  type: EstablishmentType;
  profileImage?: string;
  coverImage?: string;
  bio?: string;
  services: string[];
  openingHours?: {
    monday?: string;
    tuesday?: string;
    wednesday?: string;
    thursday?: string;
    friday?: string;
    saturday?: string;
    sunday?: string;
  };
  rating: number = 0;
  followers: number = 0;
  isVerified: boolean = false;
  isActive: boolean = true;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial?: Partial<EstablishmentProfile>) {
    Object.assign(this, partial);
  }
}
