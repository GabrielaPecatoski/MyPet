import { EstablishmentType } from '../entities/establishment-profile.entity';

export class UpdateEstablishmentProfileDto {
  name?: string;
  phone?: string;
  address?: string;
  city?: string;
  state?: string;
  zipCode?: string;
  type?: EstablishmentType;
  profileImage?: string;
  coverImage?: string;
  bio?: string;
  services?: string[];
  openingHours?: {
    monday?: string;
    tuesday?: string;
    wednesday?: string;
    thursday?: string;
    friday?: string;
    saturday?: string;
    sunday?: string;
  };
}
