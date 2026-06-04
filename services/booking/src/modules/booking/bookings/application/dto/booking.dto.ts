import type { Booking, BookingServiceItem } from "@booking/bookings/domain/models/booking.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class BookingDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() userId: string;
  @ApiProperty() userName: string;
  @ApiProperty() petId: string;
  @ApiProperty() petName: string;
  @ApiProperty() serviceName: string;
  @ApiPropertyOptional() services?: BookingServiceItem[];
  @ApiProperty() establishmentId: string;
  @ApiProperty() establishmentName: string;
  @ApiPropertyOptional() driverId?: string;
  @ApiPropertyOptional() driverName?: string;
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
    this.petId = b.petId;
    this.petName = b.petName;
    this.serviceName = b.serviceName;
    this.services = b.services.length > 0 ? b.services : undefined;
    this.establishmentId = b.establishmentId;
    this.establishmentName = b.establishmentName;
    this.driverId = b.driverId;
    this.driverName = b.driverName;
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
