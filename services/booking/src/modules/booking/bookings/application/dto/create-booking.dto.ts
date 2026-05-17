import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsDateString, IsNotEmpty, IsNumber, IsOptional, IsString, Min } from "class-validator";

export class CreateBookingDto {
  @ApiProperty() @IsString() @IsNotEmpty() petId!: string;
  @ApiProperty() @IsString() @IsNotEmpty() petName!: string;
  @ApiProperty() @IsString() @IsNotEmpty() serviceName!: string;
  @ApiProperty() @IsString() @IsNotEmpty() establishmentId!: string;
  @ApiProperty() @IsString() @IsNotEmpty() establishmentName!: string;
  @ApiProperty() @IsDateString() scheduledAt!: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) price?: number;
  @ApiPropertyOptional() @IsOptional() @IsString() userName?: string;
}
