import { IsString, IsOptional } from 'class-validator';

export class CreateEstablishmentDto {
  @IsString() name: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsString() address?: string;
  @IsOptional() @IsString() city?: string;
  @IsOptional() @IsString() phone?: string;
  @IsOptional() @IsString() imageUrl?: string;
}
