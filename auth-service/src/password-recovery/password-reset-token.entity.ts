// @ts-ignore
import { v4 as uuidv4 } from 'uuid';

export class PasswordResetToken {
  id: string;
  userId: string;
  email: string;
  token: string;
  expiresAt: Date;
  isUsed: boolean;
  createdAt: Date;
  usedAt?: Date;

  constructor(userId: string, email: string, expirationMinutes: number = 60) {
    this.id = uuidv4();
    this.userId = userId;
    this.email = email;
    this.token = this.generateSecureToken();
    this.isUsed = false;
    this.createdAt = new Date();
    
    this.expiresAt = new Date();
    this.expiresAt.setMinutes(this.expiresAt.getMinutes() + expirationMinutes);
  }

  private generateSecureToken(): string {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    let token = '';
    for (let i = 0; i < 32; i++) {
      token += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return token;
  }

  /**
   * Verifica se o token ainda é válido
   */
  isValid(): boolean {
    return !this.isUsed && new Date() < this.expiresAt;
  }

  /**
   * Marca o token como usado
   */
  markAsUsed(): void {
    this.isUsed = true;
    this.usedAt = new Date();
  }
}
