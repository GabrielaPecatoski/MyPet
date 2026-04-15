import { IsString, IsOptional } from 'class-validator';

export class CreateBookingDto {
  @IsString() userId: string;
  @IsOptional() @IsString() petId?: string;
  @IsOptional() @IsString() petName?: string;
  @IsString() serviceName: string;
  @IsString() establishmentId: string;
  @IsOptional() @IsString() establishmentName?: string;
  @IsOptional() @IsString() establishmentOwnerId?: string;
  @IsString() scheduledAt: string;
  @IsOptional() @IsString() notes?: string;
}
