import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString, Matches, MinLength } from "class-validator";

export class ResetPasswordTokenDto {
  @ApiProperty({ example: "token-de-recuperacao" })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({ example: "NovaSenha@123", minLength: 8 })
  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).+$/, {
    message:
      "A senha deve conter letra maiuscula, minuscula, numero e caractere especial",
  })
  password!: string;
}
