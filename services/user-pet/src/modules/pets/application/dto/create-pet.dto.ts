import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsNotEmpty, IsNumber, IsOptional, IsString, Min } from "class-validator";

export class CreatePetDto {
  @ApiProperty({ example: "Rex" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "Cachorro" })
  @IsString()
  @IsNotEmpty()
  type!: string;

  @ApiProperty({ example: "Labrador" })
  @IsString()
  @IsNotEmpty()
  breed!: string;

  @ApiProperty({ example: 3 })
  @IsNumber()
  @Min(0)
  age!: number;

  @ApiProperty({ example: 12.5 })
  @IsNumber()
  @Min(0)
  weight!: number;

  @ApiPropertyOptional({ example: "https://..." })
  @IsOptional()
  @IsString()
  imageUrl?: string;

  @ApiPropertyOptional({ example: "Alérgico a frango" })
  @IsOptional()
  @IsString()
  notes?: string;
}
