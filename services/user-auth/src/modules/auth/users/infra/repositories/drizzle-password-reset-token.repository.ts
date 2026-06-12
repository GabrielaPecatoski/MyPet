import { PasswordResetToken } from "@auth/users/domain/models/password-reset-token.entity";
import type { PasswordResetTokenRepository } from "@auth/users/domain/repositories/password-reset-token-repository.interface";
import { passwordResetTokensSchema } from "@auth/users/infra/database/schemas/password-reset-token.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DrizzlePasswordResetTokenRepository implements PasswordResetTokenRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(token: PasswordResetToken): Promise<void> {
    await this.drizzleService.db.insert(passwordResetTokensSchema).values({
      userId: token.userId,
      token: token.token,
      expiresAt: token.expiresAt,
      createdAt: new Date(),
    });
  }

  async findByToken(tokenStr: string): Promise<PasswordResetToken | null> {
    const result = await this.drizzleService.db
      .select()
      .from(passwordResetTokensSchema)
      .where(eq(passwordResetTokensSchema.token, tokenStr))
      .limit(1);

    return this.toEntity(result[0]);
  }

  async update(token: PasswordResetToken): Promise<void> {
    await this.drizzleService.db
      .update(passwordResetTokensSchema)
      .set({
        usedAt: token.usedAt,
      })
      .where(eq(passwordResetTokensSchema.id, token.id));
  }

  async deleteByUserId(userId: string): Promise<void> {
    await this.drizzleService.db
      .delete(passwordResetTokensSchema)
      .where(eq(passwordResetTokensSchema.userId, userId));
  }

  private toEntity(row: typeof passwordResetTokensSchema.$inferSelect | undefined): PasswordResetToken | null {
    if (!row) return null;
    return PasswordResetToken.restore({
      id: row.id,
      userId: row.userId,
      token: row.token,
      expiresAt: row.expiresAt,
      usedAt: row.usedAt ?? undefined,
      createdAt: row.createdAt,
    });
  }
}
