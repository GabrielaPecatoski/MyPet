import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString } from "class-validator";

export class CreateConversationDto {
  @ApiProperty() @IsString() @IsNotEmpty() bookingId: string;
  @ApiProperty() @IsString() @IsNotEmpty() clientId: string;
  @ApiProperty() @IsString() @IsNotEmpty() establishmentId: string;
}
