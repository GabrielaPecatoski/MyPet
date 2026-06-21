import { PasswordResetToken } from "@auth/users/domain/models/password-reset-token.entity";
import type { PasswordResetTokenRepository } from "@auth/users/domain/repositories/password-reset-token-repository.interface";
import { passwordResetTokensSchema } from "@auth/users/infra/database/schemas/password-reset-token.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { and, eq, isNull } from "drizzle-orm";

@Injectable()
export class DrizzlePasswordResetTokenRepository
  implements PasswordResetTokenRepository
{
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(token: PasswordResetToken): Promise<void> {
    await this.drizzleService.db.insert(passwordResetTokensSchema).values({
      id: token.id,
      userId: token.userId,
      token: token.token,
      expiresAt: token.expiresAt,
      usedAt: token.usedAt,
      createdAt: token.createdAt,
    });
  }

  async findByToken(token: string): Promise<PasswordResetToken | null> {
    const [row] = await this.drizzleService.db
      .select()
      .from(passwordResetTokensSchema)
      .where(eq(passwordResetTokensSchema.token, token))
      .limit(1);
    return this.toEntity(row);
  }

  async markUsed(id: string): Promise<void> {
    await this.drizzleService.db
      .update(passwordResetTokensSchema)
      .set({ usedAt: new Date() })
      .where(eq(passwordResetTokensSchema.id, id));
  }

  async deleteActiveByUserId(userId: string): Promise<void> {
    await this.drizzleService.db
      .delete(passwordResetTokensSchema)
      .where(
        and(
          eq(passwordResetTokensSchema.userId, userId),
          isNull(passwordResetTokensSchema.usedAt),
        ),
      );
  }

  private toEntity(
    row: typeof passwordResetTokensSchema.$inferSelect | undefined,
  ): PasswordResetToken | null {
    if (!row) return null;
    return PasswordResetToken.restore({
      id: row.id,
      userId: row.userId,
      token: row.token,
      expiresAt: row.expiresAt,
      usedAt: row.usedAt,
      createdAt: row.createdAt,
    });
  }
}
