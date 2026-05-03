import { Inject, Injectable, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { RABBITMQ_CLIENT } from './constants';
import { EVENTS } from './events/events.constants';
import * as crypto from 'crypto';

export interface Review {
  id: string;
  userId: string;
  userName: string;
  establishmentId: string;
  bookingId?: string;
  rating: number;
  comment: string;
  createdAt: string;
}

export interface Complaint {
  id: string;
  userId: string;
  userName: string;
  establishmentId: string;
  bookingId?: string;
  subject: string;
  description: string;
  category: string;
  status: 'PENDENTE' | 'RESPONDIDO' | 'RESOLVIDO';
  response?: string;
  createdAt: string;
}

@Injectable()
export class AppService {
  constructor(@Inject(RABBITMQ_CLIENT) private readonly rabbitClient: ClientProxy) {}

  private reviews: Review[] = [
    {
      id: 'rev-001',
      userId: 'user-001',
      userName: 'Ana Paula',
      establishmentId: 'estab-001',
      rating: 5,
      comment: 'Excelente serviço! Meu pet adorou.',
      createdAt: new Date(Date.now() - 7 * 86400000).toISOString(),
    },
    {
      id: 'rev-002',
      userId: 'user-002',
      userName: 'Carlos Silva',
      establishmentId: 'estab-001',
      rating: 4,
      comment: 'Bom atendimento, preços razoáveis.',
      createdAt: new Date(Date.now() - 14 * 86400000).toISOString(),
    },
    {
      id: 'rev-003',
      userId: 'user-003',
      userName: 'Maria Santos',
      establishmentId: 'estab-002',
      rating: 5,
      comment: 'Clínica ótima, muito profissional.',
      createdAt: new Date(Date.now() - 3 * 86400000).toISOString(),
    },
  ];

  private complaints: Complaint[] = [
    {
      id: 'comp-001',
      userId: 'user-004',
      userName: 'João Costa',
      establishmentId: 'estab-001',
      subject: 'Demora no atendimento',
      description: 'Aguardei mais de 2 horas pelo serviço agendado.',
      category: 'Atendimento',
      status: 'PENDENTE',
      createdAt: new Date(Date.now() - 2 * 86400000).toISOString(),
    },
  ];

  getByEstablishment(establishmentId: string): Review[] {
    return this.reviews.filter((r) => r.establishmentId === establishmentId);
  }

  createReview(data: Omit<Review, 'id' | 'createdAt'>): Review {
    const review: Review = { ...data, id: crypto.randomUUID(), createdAt: new Date().toISOString() };
    this.reviews.push(review);
    this.rabbitClient.emit(EVENTS.REVIEW_CREATED, {
      reviewId: review.id,
      userId: review.userId,
      establishmentId: review.establishmentId,
      rating: review.rating,
      createdAt: review.createdAt,
    });
    return review;
  }

  getComplaintsByEstab(establishmentId: string): Complaint[] {
    return this.complaints.filter((c) => c.establishmentId === establishmentId);
  }

  respondComplaint(id: string, response: string): Complaint {
    const idx = this.complaints.findIndex((c) => c.id === id);
    if (idx === -1) throw new NotFoundException('Reclamação não encontrada');
    this.complaints[idx] = { ...this.complaints[idx], response, status: 'RESPONDIDO' };
    return this.complaints[idx];
  }

  getAllComplaints(): Complaint[] {
    return this.complaints;
  }

  resolveComplaint(id: string): Complaint {
    const idx = this.complaints.findIndex((c) => c.id === id);
    if (idx === -1) throw new NotFoundException('Reclamação não encontrada');
    this.complaints[idx] = { ...this.complaints[idx], status: 'RESOLVIDO' };
    return this.complaints[idx];
  }

  deleteComplaint(id: string): void {
    const idx = this.complaints.findIndex((c) => c.id === id);
    if (idx === -1) throw new NotFoundException('Reclamação não encontrada');
    this.complaints.splice(idx, 1);
  }
}
