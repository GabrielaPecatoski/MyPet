import { Injectable, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';

export interface Service {
  id: string;
  name: string;
  price: number;
  durationMinutes: number;
}

export interface Establishment {
  id: string;
  ownerId: string;
  name: string;
  description: string;
  address: string;
  city: string;
  phone: string;
  rating: number;
  reviewCount: number;
  services: Service[];
  imageUrl?: string;
}

@Injectable()
export class AppService {
  private establishments: Establishment[] = [
    {
      id: 'estab-001',
      ownerId: 'vendedor-001',
      name: 'Pet Shop Amor & Carinho',
      description: 'Cuidados completos para o seu pet com amor e profissionalismo.',
      address: 'Rua das Flores, 123',
      city: 'São Paulo',
      phone: '(11) 3456-7890',
      rating: 4.6,
      reviewCount: 47,
      services: [
        { id: 'svc-001', name: 'Banho', price: 50.00, durationMinutes: 60 },
        { id: 'svc-002', name: 'Tosa', price: 80.00, durationMinutes: 90 },
        { id: 'svc-003', name: 'Banho e Tosa', price: 80.00, durationMinutes: 120 },
        { id: 'svc-004', name: 'Consulta Veterinária', price: 120.00, durationMinutes: 45 },
        { id: 'svc-005', name: 'Vacinação', price: 60.00, durationMinutes: 20 },
      ],
    },
    {
      id: 'estab-002',
      ownerId: 'vendedor-002',
      name: 'Clínica VetCare',
      description: 'Atendimento veterinário especializado 24h.',
      address: 'Av. Paulista, 456',
      city: 'São Paulo',
      phone: '(11) 4567-8901',
      rating: 4.8,
      reviewCount: 123,
      services: [
        { id: 'svc-101', name: 'Consulta', price: 150.00, durationMinutes: 30 },
        { id: 'svc-102', name: 'Vacinação', price: 70.00, durationMinutes: 15 },
        { id: 'svc-103', name: 'Exame de Sangue', price: 200.00, durationMinutes: 20 },
      ],
    },
    {
      id: 'estab-003',
      ownerId: 'vendedor-003',
      name: 'PetSpa Premium',
      description: 'Spa e estética para seu pet com produtos premium.',
      address: 'Rua Oscar Freire, 789',
      city: 'São Paulo',
      phone: '(11) 5678-9012',
      rating: 4.4,
      reviewCount: 89,
      services: [
        { id: 'svc-201', name: 'Banho Premium', price: 90.00, durationMinutes: 90 },
        { id: 'svc-202', name: 'Tosa Artística', price: 120.00, durationMinutes: 120 },
        { id: 'svc-203', name: 'Hidratação', price: 60.00, durationMinutes: 60 },
      ],
    },
  ];

  findAll(search?: string): Establishment[] {
    if (!search) return this.establishments;
    const q = search.toLowerCase();
    return this.establishments.filter(
      (e) => e.name.toLowerCase().includes(q) || e.city.toLowerCase().includes(q),
    );
  }

  findById(id: string): Establishment {
    const e = this.establishments.find((e) => e.id === id);
    if (!e) throw new NotFoundException('Estabelecimento não encontrado');
    return e;
  }

  findByOwner(ownerId: string): Establishment[] {
    return this.establishments.filter((e) => e.ownerId === ownerId);
  }

  create(ownerId: string, data: any): Establishment {
    const estab: Establishment = {
      ...data,
      id: crypto.randomUUID(),
      ownerId,
      rating: 0,
      reviewCount: 0,
      services: [],
    };
    this.establishments.push(estab);
    return estab;
  }

  update(id: string, data: Partial<Establishment>): Establishment {
    const idx = this.establishments.findIndex((e) => e.id === id);
    if (idx === -1) throw new NotFoundException('Estabelecimento não encontrado');
    this.establishments[idx] = { ...this.establishments[idx], ...data };
    return this.establishments[idx];
  }

  addService(establishmentId: string, service: Omit<Service, 'id'>): Establishment {
    const estab = this.findById(establishmentId);
    const newService: Service = { ...service, id: crypto.randomUUID() };
    estab.services.push(newService);
    return estab;
  }

  removeService(establishmentId: string, serviceId: string): Establishment {
    const estab = this.findById(establishmentId);
    estab.services = estab.services.filter((s) => s.id !== serviceId);
    return estab;
  }
}
