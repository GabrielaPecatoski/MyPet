import type { Review } from "@review/reviews/domain/models/review.entity";

export const REVIEW_REPOSITORY = Symbol("REVIEW_REPOSITORY");

export interface ReviewRepository {
  create(review: Review): Promise<void>;
  findByEstablishmentId(establishmentId: string): Promise<Review[]>;
  findByUserId(userId: string): Promise<Review[]>;
  getStats(establishmentId: string): Promise<{ average: number; count: number }>;
  getAdminStats(): Promise<{ avgRating: number; totalReviews: number }>;
}
