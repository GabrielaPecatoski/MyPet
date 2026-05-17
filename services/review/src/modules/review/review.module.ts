import { Module } from "@nestjs/common";
import { ReviewService } from "@review/reviews/application/services/review.service";
import { REVIEW_REPOSITORY } from "@review/reviews/domain/repositories/review-repository.interface";
import { COMPLAINT_REPOSITORY } from "@review/complaints/domain/repositories/complaint-repository.interface";
import { DrizzleReviewRepository } from "@review/reviews/infra/repositories/drizzle-review.repository";
import { DrizzleComplaintRepository } from "@review/complaints/infra/repositories/drizzle-complaint.repository";
import { ReviewsController } from "@review/reviews/infra/controllers/reviews.controller";

@Module({
  controllers: [ReviewsController],
  providers: [
    ReviewService,
    DrizzleReviewRepository,
    DrizzleComplaintRepository,
    { provide: REVIEW_REPOSITORY, useExisting: DrizzleReviewRepository },
    { provide: COMPLAINT_REPOSITORY, useExisting: DrizzleComplaintRepository },
  ],
})
export class ReviewModule {}
