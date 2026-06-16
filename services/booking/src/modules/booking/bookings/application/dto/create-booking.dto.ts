import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { Type } from "class-transformer";
import {
  IsArray,
  IsBoolean,
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
  @ApiProperty() @IsString() @IsNotEmpty() serviceName!: string;
  @ApiPropertyOptional() @IsOptional() @IsString() establishmentId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() establishmentName?: string;
  @ApiProperty() @IsDateString() scheduledAt!: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) price?: number;
  @ApiPropertyOptional() @IsOptional() @IsBoolean() priceVariable?: boolean;
  @ApiPropertyOptional() @IsOptional() @IsString() userName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() driverId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() driverName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() vetId?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() vetName?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() address?: string;
  @ApiPropertyOptional({ type: [ServiceItemDto] })
  @IsOptional()
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => ServiceItemDto)
  services?: ServiceItemDto[];
}
