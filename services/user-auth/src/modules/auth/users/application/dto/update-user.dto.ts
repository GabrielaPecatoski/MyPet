import { ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsEmail,
  IsOptional,
  IsString,
  Matches,
  MinLength,
} from "class-validator";

export class UpdateUserDto {
  @ApiPropertyOptional({ example: "Maria Silva" })
  @IsOptional()
  @IsString()
  name?: string;

  @ApiPropertyOptional({ example: "maria@email.com" })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional({ example: "(11) 99999-9999" })
  @IsOptional()
  @IsString()
  phone?: string;

  @ApiPropertyOptional({ example: "NovaSenha@123", minLength: 8 })
  @IsOptional()
  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).+$/, {
    message:
      "A senha deve conter letra maiuscula, minuscula, numero e caractere especial",
  })
  password?: string;
}
