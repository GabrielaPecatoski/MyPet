import { IsString, IsNumber, IsOptional, Min } from 'class-validator';

export class CreateServiceDto {
  @IsString() name: string;
  @IsNumber() @Min(0) price: number;
  @IsOptional() @IsNumber() durationMinutes?: number;
}
