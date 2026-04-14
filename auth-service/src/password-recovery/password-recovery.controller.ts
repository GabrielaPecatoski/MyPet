// @ts-ignore
import { Controller, Post, Get, Body, HttpCode, HttpStatus } from '@nestjs/common';
// @ts-ignore
import { PasswordRecoveryService } from './password-recovery.service';
// @ts-ignore
import { ForgotPasswordDto, ResetPasswordDto, VerifyResetTokenDto } from './password-recovery.dto';

@Controller('auth/password-recovery')
export class PasswordRecoveryController {
  constructor(private readonly passwordRecoveryService: PasswordRecoveryService) {}

  /**
   * Inicia o fluxo de recuperação de senha
   * Envia um email com token de reset para o usuário
   * @returns Confirmação de envio
   */
  @Post('forgot-password')
  @HttpCode(HttpStatus.OK)
  async forgotPassword(@Body() forgotPasswordDto: ForgotPasswordDto) {
    try {
      return await this.passwordRecoveryService.forgotPassword(forgotPasswordDto);
    } catch (error) {
      throw new Error(`Failed to process forgot password: ${error.message}`);
    }
  }

  /**
   * Verifica se um token de reset é válido
   * Útil para validar token antes de exibir form de reset
   * @returns Status de validade do token
   */
  @Post('verify-token')
  @HttpCode(HttpStatus.OK)
  async verifyResetToken(@Body() verifyResetTokenDto: VerifyResetTokenDto) {
    try {
      return await this.passwordRecoveryService.verifyResetToken(verifyResetTokenDto);
    } catch (error) {
      throw new Error(`Failed to verify token: ${error.message}`);
    }
  }

  /**
   * Reseta a senha do usuário utilizando o token
   * Deve vir do link clicado no email
   * @returns Confirmação de reset bem-sucedido
   */
  @Post('reset-password')
  @HttpCode(HttpStatus.OK)
  async resetPassword(@Body() resetPasswordDto: ResetPasswordDto) {
    try {
      return await this.passwordRecoveryService.resetPassword(resetPasswordDto);
    } catch (error) {
      throw new Error(`Failed to reset password: ${error.message}`);
    }
  }

  /**
   * Revoga todos os tokens de reset de um usuário por ID
   * Útil para invalidar tokens antigos
   * @returns Número de tokens revogados
   */
  @Post('revoke-tokens')
  @HttpCode(HttpStatus.OK)
  async revokeTokens(@Body() { userId }: { userId: string }) {
    try {
      return await this.passwordRecoveryService.revokeAllTokens(userId);
    } catch (error) {
      throw new Error(`Failed to revoke tokens: ${error.message}`);
    }
  }

  /**
   * Obtém estatísticas de tokens de reset
   * Admin apenas
   * @returns Estatísticas de tokens
   */
  @Get('tokens/stats')
  @HttpCode(HttpStatus.OK)
  async getTokenStats() {
    try {
      return await this.passwordRecoveryService.getTokenStats();
    } catch (error) {
      throw new Error(`Failed to fetch token stats: ${error.message}`);
    }
  }
}
