export class ForgotPasswordDto {
  email: string;
  /**
   * Email do usuário que esqueceu a senha
   * Exigido para iniciar o fluxo de reset
   */
}

export class ResetPasswordDto {
  token: string;
  /**
   * Token de reset enviado por email
   * Deve ser válido e não expirado
   */

  newPassword: string;
  /**
   * Nova senha desejada
   * Deve ter:
   * - Mínimo 8 caracteres
   * - Pelo menos 1 número
   * - Pelo menos 1 letra maiúscula
   * - Pelo menos 1 caractere especial (!@#$%^&*)
   */

  confirmPassword: string;
  /**
   * Confirmação da nova senha
   * Deve ser idêntica a newPassword
   */
}

export class VerifyResetTokenDto {
  token: string;
  /**
   * Token para verificar se ainda é válido
   */
}

export class PasswordResetResponseDto {
  success: boolean;
  message: string;
  resetToken?: string; // Para reset-password response
  expiresIn?: number; // Tempo em minutos até expiração
  email?: string; // Email para o qual foi enviado
}
