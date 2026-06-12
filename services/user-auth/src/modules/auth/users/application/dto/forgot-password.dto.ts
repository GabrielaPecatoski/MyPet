import { ApiProperty } from "@nestjs/swagger";
import { IsEmail, IsNotEmpty } from "class-validator";

export class ForgotPasswordDto {
  @ApiProperty({ example: "maria@email.com" })
  @IsEmail()
  @IsNotEmpty()
  email!: string;
}
