import { PasswordResetToken } from "@auth/users/domain/models/password-reset-token.entity";

export const PASSWORD_RESET_TOKEN_REPOSITORY = "PASSWORD_RESET_TOKEN_REPOSITORY";

export interface PasswordResetTokenRepository {
  create(token: PasswordResetToken): Promise<void>;
  findByToken(token: string): Promise<PasswordResetToken | null>;
  update(token: PasswordResetToken): Promise<void>;
  deleteByUserId(userId: string): Promise<void>;
}
