import {
  IsEmail,
  IsNotEmpty,
  IsOptional,
  IsString,
  MinLength,
  MaxLength,
  IsIn,
} from 'class-validator';

export class LoginDto {
  @IsEmail({}, { message: 'E-mail inválido' })
  @IsNotEmpty({ message: 'E-mail obrigatório' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Senha obrigatória' })
  @MinLength(6, { message: 'Senha deve ter no mínimo 6 caracteres' })
  password: string;
}

export class RegisterDto {
  @IsString()
  @IsNotEmpty({ message: 'Nome obrigatório' })
  @MaxLength(100)
  name: string;

  @IsEmail({}, { message: 'E-mail inválido' })
  @IsNotEmpty({ message: 'E-mail obrigatório' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Senha obrigatória' })
  @MinLength(6, { message: 'Senha deve ter no mínimo 6 caracteres' })
  password: string;

  @IsString()
  @IsNotEmpty({ message: 'Telefone obrigatório' })
  phone: string;

  @IsString()
  @IsNotEmpty({ message: 'CPF obrigatório' })
  cpf: string;

  @IsOptional()
  @IsString()
  @IsIn(['CLIENTE', 'VENDEDOR'])
  role?: string;

  @IsOptional()
  @IsString()
  businessName?: string;
}

export class ForgotPasswordDto {
  @IsEmail({}, { message: 'E-mail inválido' })
  @IsNotEmpty({ message: 'E-mail obrigatório' })
  email: string;
}

export class VerifyResetCodeDto {
  @IsEmail({}, { message: 'E-mail inválido' })
  @IsNotEmpty({ message: 'E-mail obrigatório' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Código obrigatório' })
  code: string;
}

export class ResetPasswordDto {
  @IsEmail({}, { message: 'E-mail inválido' })
  @IsNotEmpty({ message: 'E-mail obrigatório' })
  email: string;

  @IsString()
  @IsNotEmpty({ message: 'Código obrigatório' })
  code: string;

  @IsString()
  @IsNotEmpty({ message: 'Senha obrigatória' })
  @MinLength(6, { message: 'Senha deve ter no mínimo 6 caracteres' })
  newPassword: string;
}
