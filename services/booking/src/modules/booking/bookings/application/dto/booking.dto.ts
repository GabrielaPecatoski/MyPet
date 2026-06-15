import type {
  Booking,
  BookingServiceItem,
} from "@booking/bookings/domain/models/booking.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class BookingDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() userId: string;
  @ApiProperty() userName: string;
  @ApiPropertyOptional() userEmail?: string;
  @ApiProperty() petId: string;
  @ApiProperty() petName: string;
  @ApiPropertyOptional() petBreed?: string;
  @ApiPropertyOptional() petAge?: number;
  @ApiProperty() serviceName: string;
  @ApiPropertyOptional() services?: BookingServiceItem[];
  @ApiProperty() establishmentId: string;
  @ApiProperty() establishmentName: string;
  @ApiPropertyOptional() establishmentAddress?: string;
  @ApiProperty() scheduledAt: Date;
  @ApiProperty() price: number;
  @ApiProperty() status: string;
  @ApiProperty() createdAt: Date | undefined;

  private constructor(b: Booking) {
    this.id = b.id;
    this.userId = b.userId;
    this.userName = b.userName;
    this.userEmail = b.userEmail;
    this.petId = b.petId;
    this.petName = b.petName;
    this.petBreed = b.petBreed || undefined;
    this.petAge = b.petAge || undefined;
    this.serviceName = b.serviceName;
    this.services = b.services.length > 0 ? b.services : undefined;
    this.establishmentId = b.establishmentId;
    this.establishmentName = b.establishmentName;
    this.establishmentAddress = b.establishmentAddress || undefined;
    this.scheduledAt = b.scheduledAt;
    this.price = b.price;
    this.status = b.status;
    this.createdAt = b.createdAt;
  }

  static fromBooking(b: Booking | null): BookingDto | null {
    if (!b) return null;
    return new BookingDto(b);
  }
}
