import { IsString, IsOptional } from 'class-validator';

export class CreateComplaintDto {
  @IsString() userId: string;
  @IsOptional() @IsString() userName?: string;
  @IsString() establishmentId: string;
  @IsOptional() @IsString() bookingId?: string;
  @IsString() title: string;
  @IsString() description: string;
}
