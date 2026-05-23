import type { Establishment } from "@estab/establishments/domain/models/establishment.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class EstablishmentDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() ownerId: string;
  @ApiProperty() name: string;
  @ApiProperty() description: string;
  @ApiProperty() address: string;
  @ApiProperty() city: string;
  @ApiProperty() phone: string;
  @ApiProperty() type: string;
  @ApiProperty() rating: number;
  @ApiProperty() reviewCount: number;
  @ApiProperty() serviceCount: number;
  @ApiPropertyOptional() imageUrl?: string;

  private constructor(
    id: string | undefined,
    ownerId: string,
    name: string,
    description: string,
    address: string,
    city: string,
    phone: string,
    type: string,
    rating: number,
    reviewCount: number,
    serviceCount: number,
    imageUrl: string | undefined,
  ) {
    this.id = id;
    this.ownerId = ownerId;
    this.name = name;
    this.description = description;
    this.address = address;
    this.city = city;
    this.phone = phone;
    this.type = type;
    this.rating = rating;
    this.reviewCount = reviewCount;
    this.serviceCount = serviceCount;
    this.imageUrl = imageUrl;
  }

  static fromEstablishment(e: (Establishment & { serviceCount?: number }) | null): EstablishmentDto | null {
    if (!e) return null;
    return new EstablishmentDto(e.id, e.ownerId, e.name, e.description, e.address, e.city, e.phone, e.type, e.rating, e.reviewCount, e.serviceCount ?? 0, e.imageUrl);
  }
}
