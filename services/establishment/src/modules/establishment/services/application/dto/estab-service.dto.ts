import type { EstabService } from "@estab/services/domain/models/estab-service.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class EstabServiceDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() establishmentId: string;
  @ApiProperty() name: string;
  @ApiProperty() price: number;
  @ApiProperty() priceVariable: boolean;
  @ApiProperty() durationMinutes: number;
  @ApiProperty() description: string;
  @ApiProperty() categoria: string;
  @ApiPropertyOptional() imagemUrl?: string;
  @ApiProperty() ativo: boolean;

  private constructor(
    id: string | undefined,
    establishmentId: string,
    name: string,
    price: number,
    priceVariable: boolean,
    durationMinutes: number,
    description: string,
    categoria: string,
    imagemUrl: string | undefined,
    ativo: boolean,
  ) {
    this.id = id;
    this.establishmentId = establishmentId;
    this.name = name;
    this.price = price;
    this.priceVariable = priceVariable;
    this.durationMinutes = durationMinutes;
    this.description = description;
    this.categoria = categoria;
    this.imagemUrl = imagemUrl;
    this.ativo = ativo;
  }

  static fromService(s: EstabService | null): EstabServiceDto | null {
    if (!s) return null;
    return new EstabServiceDto(
      s.id,
      s.establishmentId,
      s.name,
      s.price,
      s.priceVariable,
      s.durationMinutes,
      s.description,
      s.categoria,
      s.imagemUrl,
      s.ativo,
    );
  }
}
