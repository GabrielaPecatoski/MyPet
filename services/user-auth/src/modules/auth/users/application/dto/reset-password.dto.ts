import { ApiProperty } from "@nestjs/swagger";
import { IsNotEmpty, IsString } from "class-validator";
import { IsStrongPassword } from "@common/validators";

export class ResetPasswordDto {
  @ApiProperty({ example: "token-here" })
  @IsString()
  @IsNotEmpty()
  token!: string;

  @ApiProperty({ example: "novaSenha@123", description: "Mínimo 8 caracteres, com letra maiúscula, minúscula, número e caractere especial" })
  @IsString()
  @IsNotEmpty()
  @IsStrongPassword()
  newPassword!: string;
}
