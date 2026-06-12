import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEnum,
  IsNotEmpty,
  IsOptional,
  IsString,
  IsUUID,
} from "class-validator";

export class CreateDriverDto {
  @ApiPropertyOptional() @IsUUID() @IsOptional() establishmentId?: string;
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty() @IsString() @IsNotEmpty() phone!: string;
  @ApiProperty() @IsString() @IsNotEmpty() cpf!: string;
  @ApiProperty() @IsString() @IsNotEmpty() cnh!: string;
  @ApiProperty({ enum: ["CARRO", "MOTO", "VAN"] })
  @IsEnum(["CARRO", "MOTO", "VAN"])
  vehicleType!: string;
  @ApiProperty() @IsString() @IsNotEmpty() vehicleModel!: string;
  @ApiProperty() @IsString() @IsNotEmpty() vehiclePlate!: string;
}
