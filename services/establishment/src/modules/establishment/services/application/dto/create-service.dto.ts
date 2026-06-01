import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsBoolean, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from "class-validator";

export class CreateServiceDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) price?: number;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() priceVariable?: boolean;
  @ApiProperty() @IsNumber() @Min(1) durationMinutes!: number;
  @ApiPropertyOptional() @IsOptional() @IsString() description?: string;
}
