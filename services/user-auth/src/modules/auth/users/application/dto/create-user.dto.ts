import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString } from "class-validator";
import { IsStrongPassword } from "@common/validators";

export class CreateUserDto {
  @ApiProperty({ example: "Maria Silva" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "maria@email.com" })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: "Senha@123", description: "Mínimo 8 caracteres, com letra maiúscula, minúscula, número e caractere especial" })
  @IsString()
  @IsNotEmpty()
  @IsStrongPassword()
  password!: string;

  @ApiProperty({ example: "(11) 99999-9999" })
  @IsString()
  @IsNotEmpty()
  phone!: string;

  @ApiProperty({ example: "123.456.789-00" })
  @IsString()
  @IsNotEmpty()
  cpf!: string;

  @ApiPropertyOptional({ enum: ["ADMIN", "CLIENTE", "VENDEDOR"], default: "CLIENTE" })
  @IsOptional()
  @IsIn(["ADMIN", "CLIENTE", "VENDEDOR"])
  role?: "ADMIN" | "CLIENTE" | "VENDEDOR";

  @ApiPropertyOptional({ example: "Pet Shop da Maria" })
  @IsOptional()
  @IsString()
  businessName?: string;
}
