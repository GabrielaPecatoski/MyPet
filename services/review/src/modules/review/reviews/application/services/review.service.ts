import { Review } from "@review/reviews/domain/models/review.entity";
import { REVIEW_REPOSITORY, type ReviewRepository } from "@review/reviews/domain/repositories/review-repository.interface";
import { COMPLAINT_REPOSITORY, type ComplaintRepository } from "@review/complaints/domain/repositories/complaint-repository.interface";
import { Complaint, type ComplaintStatus } from "@review/complaints/domain/models/complaint.entity";
import { Inject, Injectable, Logger, NotFoundException } from "@nestjs/common";
import { SharedMessagingService } from "@shared/infra/messaging/shared-messaging.service";
import { ReviewExchangeName, ReviewRoutingKey } from "@shared/contracts/events/review-events.enum";

export interface CreateReviewDto { establishmentId: string; userName: string; bookingId?: string; rating: number; comment?: string; }
export interface CreateComplaintDto { establishmentId: string; bookingId?: string; subject: string; description: string; category?: string; }

@Injectable()
export class ReviewService {
  private readonly logger = new Logger(ReviewService.name);

  constructor(
    @Inject(REVIEW_REPOSITORY) private readonly reviewRepo: ReviewRepository,
    @Inject(COMPLAINT_REPOSITORY) private readonly complaintRepo: ComplaintRepository,
    private readonly messaging: SharedMessagingService,
  ) {}

  async createReview(userId: string, dto: CreateReviewDto): Promise<void> {
    const review = Review.restore({
      userId,
      establishmentId: dto.establishmentId,
      userName: dto.userName,
      bookingId: dto.bookingId,
      rating: dto.rating,
      comment: dto.comment ?? "",
    })!;
    await this.reviewRepo.create(review);
    const stats = await this.reviewRepo.getStats(dto.establishmentId);
    await this.safePublish(ReviewExchangeName.CREATED, ReviewRoutingKey.CREATED, {
      reviewId: review.id!,
      establishmentId: dto.establishmentId,
      userId,
      rating: dto.rating,
      newAverage: stats.average,
      newCount: stats.count,
    });
  }

  async getReviewsByUser(userId: string) {
    const reviews = await this.reviewRepo.findByUserId(userId);
    return reviews.map((r) => ({
      id: r.id,
      establishmentId: r.establishmentId,
      bookingId: r.bookingId ?? null,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.createdAt,
    }));
  }

  async getReviews(establishmentId: string) {
    const reviews = await this.reviewRepo.findByEstablishmentId(establishmentId);
    return reviews.map((r) => ({
      id: r.id,
      establishmentId: r.establishmentId,
      userId: r.userId,
      userName: r.userName,
      rating: r.rating,
      comment: r.comment,
      createdAt: r.createdAt,
    }));
  }

  async getStats(establishmentId: string) {
    return this.reviewRepo.getStats(establishmentId);
  }

  async getAdminStats() {
    return this.reviewRepo.getAdminStats();
  }

  async createComplaint(userId: string, userName: string, dto: CreateComplaintDto): Promise<void> {
    const complaint = Complaint.restore({
      userId,
      userName,
      establishmentId: dto.establishmentId,
      bookingId: dto.bookingId,
      subject: dto.subject,
      description: dto.description,
      category: dto.category ?? "",
      status: "PENDENTE",
    })!;
    await this.complaintRepo.create(complaint);
    await this.safePublish(ReviewExchangeName.COMPLAINT_CREATED, ReviewRoutingKey.COMPLAINT_CREATED, {
      establishmentId: dto.establishmentId,
      userId,
      subject: dto.subject,
    });
  }

  async getComplaints(status?: string) {
    const complaints = await this.complaintRepo.findAll(status);
    return complaints.map(this._toComplaintDto);
  }

  async getComplaintsByEstablishment(establishmentId: string) {
    const complaints = await this.complaintRepo.findByEstablishmentId(establishmentId);
    return complaints.map(this._toComplaintDto);
  }

  private _toComplaintDto(c: Complaint) {
    return {
      id: c.id,
      establishmentId: c.establishmentId,
      userId: c.userId,
      userName: c.userName,
      bookingId: c.bookingId,
      subject: c.subject,
      description: c.description,
      category: c.category,
      status: c.status,
      response: c.response,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    };
  }

  async resolveComplaint(id: string): Promise<object> {
    const c = await this.complaintRepo.findById(id);
    if (!c) throw new NotFoundException("Reclamação não encontrada");
    c.withStatus("RESOLVIDA");
    await this.complaintRepo.update(c);
    return this._toComplaintDto(c);
  }

  async rejectComplaint(id: string): Promise<object> {
    const c = await this.complaintRepo.findById(id);
    if (!c) throw new NotFoundException("Reclamação não encontrada");
    c.withStatus("REJEITADA");
    await this.complaintRepo.update(c);
    return this._toComplaintDto(c);
  }

  async respondToComplaint(id: string, response: string): Promise<object> {
    const c = await this.complaintRepo.findById(id);
    if (!c) throw new NotFoundException("Reclamação não encontrada");
    c.withResponse(response).withStatus("EM_ANALISE");
    await this.complaintRepo.update(c);
    return this._toComplaintDto(c);
  }

  async deleteComplaint(id: string): Promise<void> {
    const c = await this.complaintRepo.findById(id);
    if (!c) throw new NotFoundException("Reclamação não encontrada");
    await this.complaintRepo.delete(id);
  }

  private async safePublish(exchange: string, routingKey: string, payload: unknown): Promise<void> {
    try {
      await this.messaging.assertExchange(exchange, "direct");
      await this.messaging.publish(exchange, routingKey, payload);
    } catch (err) {
      this.logger.warn(`RabbitMQ publish failed [${routingKey}]: ${err}`);
    }
  }
}
