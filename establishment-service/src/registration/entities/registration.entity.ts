export enum RegistrationStatus {
  PENDING = 'PENDING',
  APPROVED = 'APPROVED',
  REJECTED = 'REJECTED',
  INACTIVE = 'INACTIVE',
}

export class Registration {
  id: string;
  name: string;
  email: string;
  phone: string;
  address: string;
  city: string;
  state: string;
  zipCode: string;
  cnpj?: string;
  services?: string[];
  description?: string;
  status: RegistrationStatus = RegistrationStatus.PENDING;
  createdAt: Date;
  updatedAt: Date;

  constructor(partial?: Partial<Registration>) {
    Object.assign(this, partial);
  }
}
