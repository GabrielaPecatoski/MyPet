import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsNotEmpty, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateVeterinarianDto {
  @ApiPropertyOptional() @IsUUID() @IsOptional() establishmentId?: string;
  @ApiProperty() @IsString() @IsNotEmpty() name!: string;
  @ApiProperty() @IsString() @IsNotEmpty() phone!: string;
  @ApiProperty() @IsString() @IsNotEmpty() cpf!: string;
  @ApiProperty() @IsString() @IsNotEmpty() crmv!: string;
  @ApiPropertyOptional() @IsString() @IsOptional() especialidade?: string;
  @ApiPropertyOptional() @IsBoolean() @IsOptional() atende24h?: boolean;
  @ApiPropertyOptional() @IsBoolean() @IsOptional() atendeDomicilio?: boolean;
}

export class UpdateVetAvailabilityDto {
  @ApiPropertyOptional() @IsBoolean() @IsOptional() disponivel?: boolean;
  @ApiPropertyOptional() @IsBoolean() @IsOptional() atendeDomicilio?: boolean;
  @ApiPropertyOptional() @IsBoolean() @IsOptional() atende24h?: boolean;
}
