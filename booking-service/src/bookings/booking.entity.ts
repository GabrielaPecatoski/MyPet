// @ts-ignore
import { v4 as uuidv4 } from 'uuid';

export enum BookingStatus {
  PENDING = 'PENDING',
  CONFIRMED = 'CONFIRMED',
  IN_PROGRESS = 'IN_PROGRESS',
  COMPLETED = 'COMPLETED',
  CANCELLED = 'CANCELLED',
}

export enum ServiceType {
  GROOMING = 'GROOMING',
  CONSULTATION = 'CONSULTATION',
  VACCINATION = 'VACCINATION',
  BATH = 'BATH',
  TRAINING = 'TRAINING',
  HOTEL = 'HOTEL',
  DAYCARE = 'DAYCARE',
  SURGERY = 'SURGERY',
  DENTAL = 'DENTAL',
  OTHER = 'OTHER',
}

export class Booking {
  id: string;
  userId: string;
  petId: string;
  establishmentId: string;
  serviceType: ServiceType;
  scheduledDate: Date;
  scheduledTime: string; // HH:MM format
  duration: number; // in minutes
  status: BookingStatus;
  notes?: string;
  totalPrice?: number;
  feedback?: string;
  rating?: number;
  cancellationReason?: string;
  createdAt: Date;
  updatedAt: Date;

  constructor(
    userId: string,
    petId: string,
    establishmentId: string,
    serviceType: ServiceType,
    scheduledDate: Date,
    scheduledTime: string,
    duration: number,
  ) {
    this.id = uuidv4();
    this.userId = userId;
    this.petId = petId;
    this.establishmentId = establishmentId;
    this.serviceType = serviceType;
    this.scheduledDate = scheduledDate;
    this.scheduledTime = scheduledTime;
    this.duration = duration;
    this.status = BookingStatus.PENDING;
    this.createdAt = new Date();
    this.updatedAt = new Date();
  }
}
