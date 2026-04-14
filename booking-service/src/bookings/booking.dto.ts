import { ServiceType, BookingStatus } from '../booking.entity';

export class CreateBookingDto {
  userId: string;
  petId: string;
  establishmentId: string;
  serviceType: ServiceType;
  scheduledDate: Date;
  scheduledTime: string; // HH:MM format
  duration: number; // in minutes
  notes?: string;
  totalPrice?: number;
}

export class UpdateBookingDto {
  notes?: string;
  totalPrice?: number;
  feedback?: string;
  rating?: number;
}

export class UpdateBookingStatusDto {
  status: BookingStatus;
  cancellationReason?: string;
}

export class BookingFilterDto {
  userId?: string;
  establishmentId?: string;
  status?: BookingStatus;
  petId?: string;
  dateFrom?: Date;
  dateTo?: Date;
}
