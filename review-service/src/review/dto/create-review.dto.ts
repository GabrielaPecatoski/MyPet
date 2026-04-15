import { IsString, IsOptional, IsInt, Min, Max } from 'class-validator';

export class CreateReviewDto {
  @IsString() userId: string;
  @IsOptional() @IsString() userName?: string;
  @IsString() establishmentId: string;
  @IsOptional() @IsString() bookingId?: string;
  @IsInt() @Min(1) @Max(5) rating: number;
  @IsOptional() @IsString() comment?: string;
}
