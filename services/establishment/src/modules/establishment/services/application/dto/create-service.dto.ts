import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from "class-validator";

export class CreateServiceDto {
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty() @IsNumber() @Min(0) price!: number;
  @ApiProperty() @IsNumber() @Min(1) durationMinutes!: number;
  @ApiPropertyOptional() @IsOptional() @IsString() description?: string;
}
