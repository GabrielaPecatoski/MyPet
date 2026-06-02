import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsNumber, IsOptional, IsString, Min } from "class-validator";

export class UpdatePetDto {
  @ApiPropertyOptional() @IsOptional() @IsString() name?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() type?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() breed?: string;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) age?: number;
  @ApiPropertyOptional() @IsOptional() @IsNumber() @Min(0) weight?: number;
  @ApiPropertyOptional() @IsOptional() @IsString() imageUrl?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() notes?: string;
}
