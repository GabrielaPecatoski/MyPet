import { Review } from "@review/reviews/domain/models/review.entity";
import type { ReviewRepository } from "@review/reviews/domain/repositories/review-repository.interface";
import { reviewsSchema } from "@review/reviews/infra/database/schemas/review.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { avg, count, eq, sql } from "drizzle-orm";

@Injectable()
export class DrizzleReviewRepository implements ReviewRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(r: Review): Promise<void> {
    await this.drizzleService.db.insert(reviewsSchema).values({
      establishmentId: r.establishmentId,
      userId: r.userId,
      userName: r.userName,
      bookingId: r.bookingId ?? null,
      rating: r.rating,
      comment: r.comment,
      createdAt: new Date(),
    });
  }

  async findByEstablishmentId(establishmentId: string): Promise<Review[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(reviewsSchema)
      .where(eq(reviewsSchema.establishmentId, establishmentId));
    return rows.map((r) => Review.restore(r)!);
  }

  async findByUserId(userId: string): Promise<Review[]> {
    const rows = await this.drizzleService.db
      .select()
      .from(reviewsSchema)
      .where(eq(reviewsSchema.userId, userId));
    return rows.map((r) => Review.restore(r)!);
  }

  async getStats(establishmentId: string): Promise<{ average: number; count: number }> {
    const [result] = await this.drizzleService.db
      .select({
        average: sql<number>`coalesce(avg(${reviewsSchema.rating}), 0)::float`,
        count: sql<number>`count(*)::int`,
      })
      .from(reviewsSchema)
      .where(eq(reviewsSchema.establishmentId, establishmentId));
    return { average: Number(result?.average ?? 0), count: result?.count ?? 0 };
  }

  async getAdminStats(): Promise<{ avgRating: number; totalReviews: number }> {
    const [result] = await this.drizzleService.db
      .select({
        avgRating: sql<number>`coalesce(avg(${reviewsSchema.rating}), 0)::float`,
        totalReviews: sql<number>`count(*)::int`,
      })
      .from(reviewsSchema);
    return { avgRating: Number(result?.avgRating ?? 0), totalReviews: result?.totalReviews ?? 0 };
  }
}
