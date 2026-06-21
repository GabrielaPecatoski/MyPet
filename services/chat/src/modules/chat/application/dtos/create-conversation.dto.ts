import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsNotEmpty, IsOptional, IsString } from "class-validator";

export class CreateConversationDto {
  @ApiProperty() @IsString() @IsNotEmpty() bookingId: string;
  @ApiProperty() @IsString() @IsNotEmpty() clientId: string;
  @ApiPropertyOptional() @IsString() @IsOptional() clientName?: string;
  @ApiProperty() @IsString() @IsNotEmpty() establishmentId: string;
  @ApiPropertyOptional() @IsString() @IsOptional() establishmentName?: string;
}
