import type { PasswordResetToken } from "@auth/users/domain/models/password-reset-token.entity";

export const PASSWORD_RESET_TOKEN_REPOSITORY = Symbol(
  "PASSWORD_RESET_TOKEN_REPOSITORY",
);

export interface PasswordResetTokenRepository {
  create(token: PasswordResetToken): Promise<void>;
  findByToken(token: string): Promise<PasswordResetToken | null>;
  markUsed(id: string): Promise<void>;
  /** Invalida (apaga) os tokens ainda pendentes de um usuário antes de emitir um novo. */
  deleteActiveByUserId(userId: string): Promise<void>;
}
