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
  @ApiPropertyOptional() petPhotoUrl?: string;
  @ApiProperty() serviceName: string;
  @ApiPropertyOptional() services?: BookingServiceItem[];
  @ApiPropertyOptional() attendancePhotos?: string[];
  @ApiPropertyOptional() establishmentId?: string;
  @ApiProperty() establishmentName: string;
  @ApiPropertyOptional() establishmentAddress?: string;
  @ApiPropertyOptional() driverId?: string;
  @ApiPropertyOptional() driverName?: string;
  @ApiPropertyOptional() driverPhotoUrl?: string;
  @ApiProperty() transportStatus: string;
  @ApiProperty() transportRequested: boolean;
  @ApiPropertyOptional() vetId?: string;
  @ApiPropertyOptional() vetName?: string;
  @ApiProperty() scheduledAt: Date;
  @ApiProperty() price: number;
  @ApiProperty() priceVariable: boolean;
  @ApiProperty() status: string;
  @ApiProperty() paymentStatus: string;
  @ApiPropertyOptional() paymentMethod?: string;
  @ApiPropertyOptional() expiresAt?: Date;
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
    this.petPhotoUrl = b.petPhotoUrl;
    this.serviceName = b.serviceName;
    this.services = b.services.length > 0 ? b.services : undefined;
    this.attendancePhotos =
      b.attendancePhotos.length > 0 ? b.attendancePhotos : undefined;
    this.establishmentId = b.establishmentId;
    this.establishmentName = b.establishmentName;
    this.establishmentAddress = b.establishmentAddress || undefined;
    this.driverId = b.driverId;
    this.driverName = b.driverName;
    this.driverPhotoUrl = b.driverPhotoUrl;
    this.transportStatus = b.transportStatus;
    this.transportRequested = b.transportRequested;
    this.vetId = b.vetId;
    this.vetName = b.vetName;
    this.scheduledAt = b.scheduledAt;
    this.price = b.price;
    this.priceVariable = b.priceVariable;
    this.status = b.status;
    this.paymentStatus = b.paymentStatus;
    this.paymentMethod = b.paymentMethod;
    this.createdAt = b.createdAt;
    if (b.status === "AGUARDANDO_PAGAMENTO" && b.createdAt) {
      this.expiresAt = new Date(b.createdAt.getTime() + 60 * 60 * 1000);
    }
  }

  static fromBooking(b: Booking | null): BookingDto | null {
    if (!b) return null;
    return new BookingDto(b);
  }
}
