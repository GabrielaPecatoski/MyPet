import type { Booking } from "@booking/bookings/domain/models/booking.entity";
import { ApiProperty } from "@nestjs/swagger";

export class BookingDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() userId: string;
  @ApiProperty() userName: string;
  @ApiProperty() petId: string;
  @ApiProperty() petName: string;
  @ApiProperty() serviceName: string;
  @ApiProperty() establishmentId: string;
  @ApiProperty() establishmentName: string;
  @ApiProperty() scheduledAt: Date;
  @ApiProperty() price: number;
  @ApiProperty() status: string;
  @ApiProperty() createdAt: Date | undefined;

  private constructor(b: Booking) {
    this.id = b.id;
    this.userId = b.userId;
    this.userName = b.userName;
    this.petId = b.petId;
    this.petName = b.petName;
    this.serviceName = b.serviceName;
    this.establishmentId = b.establishmentId;
    this.establishmentName = b.establishmentName;
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
