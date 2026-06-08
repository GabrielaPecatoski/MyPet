import { Injectable } from "@nestjs/common";
import { deviceTokensSchema } from "@notification/infra/database/schemas/device-token.schema";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DeviceTokenRepository {
  constructor(private readonly drizzle: DrizzleService) {}

  async save(
    userId: string,
    token: string,
    platform = "android",
  ): Promise<void> {
    const [existing] = await this.drizzle.db
      .select()
      .from(deviceTokensSchema)
      .where(eq(deviceTokensSchema.userId, userId))
      .limit(1);

    if (existing) {
      await this.drizzle.db
        .update(deviceTokensSchema)
        .set({ token, platform })
        .where(eq(deviceTokensSchema.userId, userId));
    } else {
      await this.drizzle.db
        .insert(deviceTokensSchema)
        .values({ userId, token, platform });
    }
  }

  async findTokenByUserId(userId: string): Promise<string | null> {
    const [row] = await this.drizzle.db
      .select({ token: deviceTokensSchema.token })
      .from(deviceTokensSchema)
      .where(eq(deviceTokensSchema.userId, userId))
      .limit(1);
    return row?.token ?? null;
  }

  async deleteByUserId(userId: string): Promise<void> {
    await this.drizzle.db
      .delete(deviceTokensSchema)
      .where(eq(deviceTokensSchema.userId, userId));
  }
}
