import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsNumber, IsOptional, IsString } from "class-validator";

export class UpdateEstablishmentDto {
  @ApiPropertyOptional() @IsOptional() @IsString() name?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() description?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() address?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() city?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() phone?: string;
  @ApiPropertyOptional({ enum: ["PET_SHOP", "VETERINARIA", "HIBRIDO"] })
  @IsOptional()
  @IsString()
  type?: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() lat?: number;
  @ApiPropertyOptional() @IsOptional() @IsNumber() lng?: number;
  @ApiPropertyOptional() @IsOptional() @IsString() imageUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() crmv?: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() atendeEmergencia?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() atendimento24h?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  receberAlertaSonoro?: boolean;
  @ApiPropertyOptional()
  @IsOptional()
  @IsBoolean()
  receberPushEmergencia?: boolean;
}
