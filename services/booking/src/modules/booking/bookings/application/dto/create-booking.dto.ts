import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { Type } from "class-transformer";
import {
  IsArray,
  IsDateString,
  IsNotEmpty,
  IsNumber,
  IsOptional,
  IsString,
  Min,
  ValidateNested,
} from "class-validator";

export class ServiceItemDto {
  @ApiProperty() @IsString() @IsNotEmpty() id!: string;
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty() @IsNumber() @Min(0) price!: number;
  @ApiProperty() @IsNumber() @Min(1) durationMinutes!: number;
}

export class CreateBookingDto {
  @ApiProperty() @IsString() @IsNotEmpty() petId!: string;
  @ApiProperty() @IsString() @IsNotEmpty() petName!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() petBreed?: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) petAge?: number;
  @ApiProperty() @IsString() @IsNotEmpty() serviceName!: string;
  @ApiProperty() @IsString() @IsNotEmpty() establishmentId!: string;
  @ApiProperty() @IsString() @IsNotEmpty() establishmentName!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() establishmentAddress?: string;
  @ApiProperty() @IsDateString() scheduledAt!: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) price?: number;
  @ApiPropertyOptional() @IsOptional() @IsString() userName?: string;
  @ApiPropertyOptional({ type: [ServiceItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ServiceItemDto)
  services?: ServiceItemDto[];
}
