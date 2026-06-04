import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsNotEmpty, IsOptional, IsString } from "class-validator";

export class CreateEstablishmentDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty() @IsString() @IsNotEmpty() description!: string;
  @ApiProperty() @IsString() @IsNotEmpty() address!: string;
  @ApiProperty() @IsString() @IsNotEmpty() city!: string;
  @ApiProperty() @IsString() @IsNotEmpty() phone!: string;
  @ApiProperty({ example: "PET_SHOP", enum: ["PET_SHOP", "VETERINARIA", "HIBRIDO"] })
  @IsString() @IsNotEmpty() type!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() imageUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() crmv?: string;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() atendeEmergencia?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() atendimento24h?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() receberAlertaSonoro?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() receberPushEmergencia?: boolean;
}
