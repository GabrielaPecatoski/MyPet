import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";
import { IsEmail, IsIn, IsNotEmpty, IsOptional, IsString, MinLength } from "class-validator";

export class CreateUserDto {
  @ApiProperty({ example: "Maria Silva" })
  @IsString()
  @IsNotEmpty()
  name!: string;

  @ApiProperty({ example: "maria@email.com" })
  @IsEmail()
  @IsNotEmpty()
  email!: string;

  @ApiProperty({ example: "senha123", minLength: 6 })
  @IsString()
  @MinLength(6)
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
