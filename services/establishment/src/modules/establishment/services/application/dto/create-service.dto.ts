import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsBoolean,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
} from "class-validator";

export class CreateServiceDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) price?: number;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() priceVariable?: boolean;
  @ApiProperty() @IsNumber() @Min(1) durationMinutes!: number;
  @ApiPropertyOptional() @IsOptional() @IsString() description?: string;
  @ApiPropertyOptional({
    example: "outros",
    enum: [
      "banho",
      "tosa",
      "consulta_veterinaria",
      "vacinacao",
      "exames",
      "cirurgias",
      "internacao",
      "emergencia",
      "medicamentos",
      "atendimento_domiciliar",
      "outros",
    ],
  })
  @IsOptional()
  @IsString()
  categoria?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() imagemUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() ativo?: boolean;
}
