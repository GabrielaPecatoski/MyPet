export enum UserRole {
  USER = 'USER',
  PET_OWNER = 'PET_OWNER',
  ESTABLISHMENT_OWNER = 'ESTABLISHMENT_OWNER',
  ADMIN = 'ADMIN',
}

export class User {
  id: string;
  email: string;
  name: string;
  phone: string;
  birthDate: string;
  cpf: string;
  profileImage?: string;
  bio?: string;
  role: UserRole = UserRole.USER;
  isActive: boolean = true;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial?: Partial<User>) {
    Object.assign(this, partial);
  }
}
