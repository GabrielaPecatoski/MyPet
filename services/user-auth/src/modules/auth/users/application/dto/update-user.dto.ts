import { ApiPropertyOptional } from "@nestjs/swagger";
import { IsEmail, IsOptional, IsString } from "class-validator";
import { IsStrongPassword } from "@common/validators";

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

  @ApiPropertyOptional({ example: "novaSenha@123", description: "Mínimo 8 caracteres, com letra maiúscula, minúscula, número e caractere especial" })
  @IsOptional()
  @IsString()
  @IsStrongPassword()
  password?: string;
}
