import type { EstabService } from "@estab/services/domain/models/estab-service.entity";
import { ApiProperty } from "@nestjs/swagger";

export class EstabServiceDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() establishmentId: string;
  @ApiProperty() name: string;
  @ApiProperty() price: number;
  @ApiProperty() priceVariable: boolean;
  @ApiProperty() durationMinutes: number;
  @ApiProperty() description: string;

  private constructor(
    id: string | undefined,
    establishmentId: string,
    name: string,
    price: number,
    priceVariable: boolean,
    durationMinutes: number,
    description: string,
  ) {
    this.id = id;
    this.establishmentId = establishmentId;
    this.name = name;
    this.price = price;
    this.priceVariable = priceVariable;
    this.durationMinutes = durationMinutes;
    this.description = description;
  }

  static fromService(s: EstabService | null): EstabServiceDto | null {
    if (!s) return null;
    return new EstabServiceDto(s.id, s.establishmentId, s.name, s.price, s.priceVariable, s.durationMinutes, s.description);
  }
}
