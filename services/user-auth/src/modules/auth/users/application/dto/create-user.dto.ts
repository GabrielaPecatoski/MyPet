import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import {
  IsDateString,
  IsEmail,
  IsIn,
  IsNotEmpty,
  IsOptional,
  IsString,
  Matches,
  MinLength,
} from "class-validator";

export class CreateUserDto {
  @ApiProperty({ example: "Maria Silva" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "maria@email.com" })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: "Senha@123", minLength: 8 })
  @IsString()
  @MinLength(8)
  @Matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z\d]).+$/, {
    message:
      "A senha deve conter letra maiuscula, minuscula, numero e caractere especial",
  })
  password!: string;

  @ApiProperty({ example: "(11) 99999-9999" })
  @IsString()
  @IsNotEmpty()
  phone!: string;

  @ApiProperty({ example: "123.456.789-00" })
  @IsString()
  @IsNotEmpty()
  cpf!: string;

  @ApiPropertyOptional({ example: "1990-05-20", description: "Data de nascimento (ISO). É obrigatório ter 18+ anos." })
  @IsOptional()
  @IsDateString()
  birthDate?: string;

  @ApiPropertyOptional({
    enum: ["ADMIN", "CLIENTE", "VENDEDOR", "MOTORISTA", "VETERINARIO"],
    default: "CLIENTE",
  })
  @IsOptional()
  @IsIn(["ADMIN", "CLIENTE", "VENDEDOR", "MOTORISTA", "VETERINARIO"])
  role?: "ADMIN" | "CLIENTE" | "VENDEDOR" | "MOTORISTA" | "VETERINARIO";

  @ApiPropertyOptional({ example: "Pet Shop da Maria" })
  @IsOptional()
  @IsString()
  businessName?: string;
}
