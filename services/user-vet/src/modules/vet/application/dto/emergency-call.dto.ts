import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsNotEmpty, IsOptional, IsString } from "class-validator";

export class CreateEmergencyCallDto {
  @ApiProperty() @IsString() @IsNotEmpty() callerName!: string;
  @ApiPropertyOptional() @IsString() @IsOptional() callerPhone?: string;
  @ApiPropertyOptional() @IsString() @IsOptional() petDescription?: string;
}
