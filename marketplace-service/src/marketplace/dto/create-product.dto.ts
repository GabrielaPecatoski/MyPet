import { IsString, IsNumber, IsOptional, Min } from 'class-validator';

export class CreateProductDto {
  @IsString() name: string;
  @IsOptional() @IsString() brand?: string;
  @IsNumber() @Min(0) price: number;
  @IsOptional() @IsString() unit?: string;
  @IsOptional() @IsString() category?: string;
  @IsOptional() @IsString() description?: string;
  @IsOptional() @IsNumber() @Min(0) stock?: number;
  @IsOptional() @IsString() imageUrl?: string;
}
