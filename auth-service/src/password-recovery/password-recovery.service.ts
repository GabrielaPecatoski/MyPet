// @ts-ignore
import { Injectable } from '@nestjs/common';
// @ts-ignore
import { PasswordResetToken } from './password-reset-token.entity';
// @ts-ignore
import { ForgotPasswordDto, ResetPasswordDto, VerifyResetTokenDto, PasswordResetResponseDto } from './password-recovery.dto';

@Injectable()
export class PasswordRecoveryService {
  private resetTokens: PasswordResetToken[] = [];
  private users: any[] = []; // Simulação de banco de dados de usuários

  constructor() {
    // Inicializa com alguns usuários de teste
    this.users = [
      {
        id: 'user-123',
        email: 'user@example.com',
        name: 'João Silva',
        password: 'hashedPassword123',
      },
    ];
  }

  /**
   * Valida formato de email
   * @param email Email a validar
   * @returns true se válido
   */
  private validateEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }

  /**
   * Valida força da senha
   * Requisitos:
   * - Mínimo 8 caracteres
   * - Pelo menos 1 número
   * - Pelo menos 1 letra maiúscula
   * - Pelo menos 1 caractere especial
   * @param password Senha a validar
   * @returns true se válida
   */
  private validatePasswordStrength(password: string): {
    isValid: boolean;
    errors: string[];
  } {
    const errors: string[] = [];

    if (password.length < 8) {
      errors.push('Senha deve ter no mínimo 8 caracteres');
    }

    if (!/\d/.test(password)) {
      errors.push('Senha deve conter pelo menos 1 número');
    }

    if (!/[A-Z]/.test(password)) {
      errors.push('Senha deve conter pelo menos 1 letra maiúscula');
    }

    if (!/[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]/.test(password)) {
      errors.push('Senha deve conter pelo menos 1 caractere especial (!@#$%^&*)');
    }

    return {
      isValid: errors.length === 0,
      errors,
    };
  }

  /**
   * Inicia o fluxo de recuperação de senha
   * Procura usuário por email e cria token de reset
   * @param forgotPasswordDto DTO com email
   * @returns Response com token e informações
   */
  async forgotPassword(forgotPasswordDto: ForgotPasswordDto): Promise<PasswordResetResponseDto> {
    const { email } = forgotPasswordDto;

    // Validar email
    if (!email || !email.trim()) {
      throw new Error('Email is required');
    }

    if (!this.validateEmail(email.trim())) {
      throw new Error('Invalid email format');
    }

    const normalizedEmail = email.trim().toLowerCase();

    // Procurar usuário por email
    const user = this.users.find((u) => u.email.toLowerCase() === normalizedEmail);

    if (!user) {
      // Por segurança, retorna mensagem genérica
      // Não revela se email existe ou não no sistema
      return {
        success: true,
        message: 'Se o email existir em nossa base de dados, um link de recuperação será enviado',
        email: normalizedEmail,
      };
    }

    // Criar token de reset
    const resetToken = new PasswordResetToken(user.id, user.email, 60); // 1 hora

    // Salvar token
    this.resetTokens.push(resetToken);

    // Limpar tokens expirados
    this.cleanExpiredTokens();

    return {
      success: true,
      message: 'Email de recuperação enviado com sucesso',
      resetToken: resetToken.token, // Em produção, não retornaria o token
      expiresIn: 60,
      email: normalizedEmail,
    };
  }

  /**
   * Verifica se um token de reset é válido
   * @param verifyResetTokenDto DTO com token
   * @returns Informações do token
   */
  async verifyResetToken(verifyResetTokenDto: VerifyResetTokenDto): Promise<{
    valid: boolean;
    message: string;
    expiresAt?: Date;
    email?: string;
  }> {
    const { token } = verifyResetTokenDto;

    if (!token || !token.trim()) {
      throw new Error('Token is required');
    }

    const resetToken = this.resetTokens.find((rt) => rt.token === token.trim());

    if (!resetToken) {
      return {
        valid: false,
        message: 'Token inválido ou não encontrado',
      };
    }

    if (!resetToken.isValid()) {
      return {
        valid: false,
        message: 'Token expirado ou já foi utilizado',
      };
    }

    return {
      valid: true,
      message: 'Token válido',
      expiresAt: resetToken.expiresAt,
      email: resetToken.email,
    };
  }

  /**
   * Reseta a senha do usuário usando o token
   * @param resetPasswordDto DTO com token e nova senha
   * @returns Response com resultado
   */
  async resetPassword(resetPasswordDto: ResetPasswordDto): Promise<PasswordResetResponseDto> {
    const { token, newPassword, confirmPassword } = resetPasswordDto;

    // Validar token
    if (!token || !token.trim()) {
      throw new Error('Token is required');
    }

    // Validar nova senha
    if (!newPassword || !newPassword.trim()) {
      throw new Error('New password is required');
    }

    if (!confirmPassword || !confirmPassword.trim()) {
      throw new Error('Password confirmation is required');
    }

    // Verificar se senhas correspondem
    if (newPassword.trim() !== confirmPassword.trim()) {
      throw new Error('Passwords do not match');
    }

    // Validar força da senha
    const passwordValidation = this.validatePasswordStrength(newPassword.trim());
    if (!passwordValidation.isValid) {
      throw new Error(passwordValidation.errors.join('. '));
    }

    // Procurar token
    const resetToken = this.resetTokens.find((rt) => rt.token === token.trim());

    if (!resetToken) {
      throw new Error('Token inválido ou não encontrado');
    }

    // Verificar validade do token
    if (!resetToken.isValid()) {
      throw new Error('Token expirado ou já foi utilizado');
    }

    // Procurar usuário
    const user = this.users.find((u) => u.id === resetToken.userId);

    if (!user) {
      throw new Error('Usuário não encontrado');
    }

    // Validar que nova senha não é a mesma que a anterior
    if (user.password === newPassword.trim()) {
      throw new Error('Nova senha não pode ser igual à senha anterior');
    }

    // Atualizar senha (em produção seria hasheada)
    user.password = newPassword.trim();
    user.updatedAt = new Date();

    // Marcar token como usado
    resetToken.markAsUsed();

    return {
      success: true,
      message: 'Senha alterada com sucesso',
      email: user.email,
    };
  }

  /**
   * Revoga todos os tokens de reset de um usuário
   * Útil após reset bem-sucedido ou por segurança
   * @param userId ID do usuário
   */
  async revokeAllTokens(userId: string): Promise<{
    success: boolean;
    revokedCount: number;
  }> {
    if (!userId || !userId.trim()) {
      throw new Error('UserId is required');
    }

    const beforeCount = this.resetTokens.length;

    // Remove todos os tokens não-utilizados do usuário
    this.resetTokens = this.resetTokens.filter(
      (rt) => rt.userId !== userId || rt.isUsed,
    );

    const revokedCount = beforeCount - this.resetTokens.length;

    return {
      success: true,
      revokedCount,
    };
  }

  /**
   * Obtém estatísticas de tokens de reset
   * @returns Estatísticas
   */
  async getTokenStats(): Promise<{
    totalTokens: number;
    validTokens: number;
    expiredTokens: number;
    usedTokens: number;
  }> {
    const now = new Date();

    const validTokens = this.resetTokens.filter((rt) => rt.isValid()).length;
    const usedTokens = this.resetTokens.filter((rt) => rt.isUsed).length;
    const expiredTokens = this.resetTokens.filter(
      (rt) => !rt.isUsed && rt.expiresAt < now,
    ).length;

    return {
      totalTokens: this.resetTokens.length,
      validTokens,
      expiredTokens,
      usedTokens,
    };
  }

  /**
   * Remove tokens expirados do banco
   * Deve ser chamado periodicamente
   */
  private cleanExpiredTokens(): void {
    const now = new Date();
    this.resetTokens = this.resetTokens.filter(
      (rt) => rt.expiresAt > now || rt.isUsed,
    );
  }

  /**
   * Agenda limpeza periódica de tokens expirados
   * Deve ser configurado no módulo
   */
  startPeriodicCleanup(intervalMinutes: number = 30): any {
    return setInterval(() => {
      this.cleanExpiredTokens();
    }, intervalMinutes * 60 * 1000);
  }
}
