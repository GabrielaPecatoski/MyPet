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
  @ApiPropertyOptional() services?: unknown[];
  @ApiPropertyOptional() lat?: number;
  @ApiPropertyOptional() lng?: number;
  @ApiPropertyOptional() imageUrl?: string;
  @ApiPropertyOptional() crmv?: string;
  @ApiProperty() atendeEmergencia: boolean;
  @ApiProperty() atendimento24h: boolean;
  @ApiProperty() receberAlertaSonoro: boolean;
  @ApiProperty() receberPushEmergencia: boolean;

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
    lat: number | undefined,
    lng: number | undefined,
    imageUrl: string | undefined,
    crmv: string | undefined,
    atendeEmergencia: boolean,
    atendimento24h: boolean,
    receberAlertaSonoro: boolean,
    receberPushEmergencia: boolean,
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
    this.lat = lat;
    this.lng = lng;
    this.imageUrl = imageUrl;
    this.crmv = crmv;
    this.atendeEmergencia = atendeEmergencia;
    this.atendimento24h = atendimento24h;
    this.receberAlertaSonoro = receberAlertaSonoro;
    this.receberPushEmergencia = receberPushEmergencia;
  }

  static fromEstablishment(
    e: (Establishment & { serviceCount?: number; services?: unknown[] }) | null,
  ): EstablishmentDto | null {
    if (!e) return null;
    const dto = new EstablishmentDto(
      e.id,
      e.ownerId,
      e.name,
      e.description,
      e.address,
      e.city,
      e.phone,
      e.type,
      e.rating,
      e.reviewCount,
      e.serviceCount ?? 0,
      e.lat,
      e.lng,
      e.imageUrl,
      e.crmv,
      e.atendeEmergencia,
      e.atendimento24h,
      e.receberAlertaSonoro,
      e.receberPushEmergencia,
    );
    if (e.services) dto.services = e.services;
    return dto;
  }
}
