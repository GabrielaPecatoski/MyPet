import { BadRequestException } from "@nestjs/common";

export interface PasswordStrengthResult {
  isStrong: boolean;
  errors: string[];
}

export class PasswordValidator {
  private static readonly MIN_LENGTH = 8;
  private static readonly UPPERCASE_PATTERN = /[A-Z]/;
  private static readonly LOWERCASE_PATTERN = /[a-z]/;
  private static readonly DIGIT_PATTERN = /[0-9]/;
  private static readonly SPECIAL_CHAR_PATTERN = /[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/;

  static validate(password: string): PasswordStrengthResult {
    const errors: string[] = [];

    if (password.length < this.MIN_LENGTH) {
      errors.push(`A senha deve ter no mínimo ${this.MIN_LENGTH} caracteres`);
    }

    if (!this.UPPERCASE_PATTERN.test(password)) {
      errors.push("A senha deve conter pelo menos uma letra maiúscula");
    }

    if (!this.LOWERCASE_PATTERN.test(password)) {
      errors.push("A senha deve conter pelo menos uma letra minúscula");
    }

    if (!this.DIGIT_PATTERN.test(password)) {
      errors.push("A senha deve conter pelo menos um número");
    }

    if (!this.SPECIAL_CHAR_PATTERN.test(password)) {
      errors.push("A senha deve conter pelo menos um caractere especial (!@#$%^&*()_+-=[]{};\\':\"|,.<>/?\\\\)");
    }

    return {
      isStrong: errors.length === 0,
      errors,
    };
  }

  static validateOrThrow(password: string): void {
    const result = this.validate(password);
    if (!result.isStrong) {
      throw new BadRequestException({
        message: "Senha não atende aos critérios de segurança",
        errors: result.errors,
      });
    }
  }
}
