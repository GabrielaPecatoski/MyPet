import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsNotEmpty, IsOptional, IsString } from "class-validator";

export class CreateEmergencyCallDto {
  @ApiProperty() @IsString() @IsNotEmpty() callerName!: string;
  @ApiProperty() @IsString() @IsNotEmpty() callerPhone!: string;
  @ApiPropertyOptional() @IsString() @IsOptional() petDescription?: string;
}
