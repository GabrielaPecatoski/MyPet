import {
  Injectable, NotFoundException, ForbiddenException, ConflictException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Review } from './entities/review.entity';
import { Complaint } from './entities/complaint.entity';
import { CreateReviewDto } from './dto/create-review.dto';
import { CreateComplaintDto } from './dto/create-complaint.dto';

@Injectable()
export class ReviewService {
  constructor(
    @InjectRepository(Review)
    private readonly reviewRepo: Repository<Review>,
    @InjectRepository(Complaint)
    private readonly complaintRepo: Repository<Complaint>,
  ) {}

  findAll(): Promise<Review[]> {
    return this.reviewRepo.find({ order: { createdAt: 'DESC' } });
  }

  findByEstablishment(establishmentId: string): Promise<Review[]> {
    return this.reviewRepo.find({
      where: { establishmentId },
      order: { createdAt: 'DESC' },
    });
  }

  findByUser(userId: string): Promise<Review[]> {
    return this.reviewRepo.find({
      where: { userId },
      order: { createdAt: 'DESC' },
    });
  }

  async averageRating(
    establishmentId: string,
  ): Promise<{ establishmentId: string; average: number; total: number }> {
    const result = await this.reviewRepo
      .createQueryBuilder('r')
      .select('AVG(r.rating)', 'average')
      .addSelect('COUNT(r.id)', 'total')
      .where('r.establishmentId = :id', { id: establishmentId })
      .getRawOne();
    return {
      establishmentId,
      average: parseFloat(result.average ?? '0'),
      total: parseInt(result.total ?? '0'),
    };
  }

  createReview(dto: CreateReviewDto): Promise<Review> {
    const review = this.reviewRepo.create(dto);
    return this.reviewRepo.save(review);
  }

  async deleteReview(id: string, userId: string, isAdmin: boolean): Promise<void> {
    const review = await this.reviewRepo.findOne({ where: { id } });
    if (!review) throw new NotFoundException('Avaliação não encontrada');
    if (!isAdmin && review.userId !== userId) {
      throw new ForbiddenException('Sem permissão para excluir esta avaliação');
    }
    await this.reviewRepo.remove(review);
  }

  findAllComplaints(userId?: string, establishmentId?: string): Promise<Complaint[]> {
    const where: Partial<Complaint> = {};
    if (userId) where.userId = userId;
    if (establishmentId) where.establishmentId = establishmentId;
    return this.complaintRepo.find({ where, order: { createdAt: 'DESC' } });
  }

  async findComplaintById(id: string): Promise<Complaint> {
    const complaint = await this.complaintRepo.findOne({ where: { id } });
    if (!complaint) throw new NotFoundException('Reclamação não encontrada');
    return complaint;
  }

  createComplaint(dto: CreateComplaintDto): Promise<Complaint> {
    const complaint = this.complaintRepo.create({ ...dto, status: 'PENDENTE' });
    return this.complaintRepo.save(complaint);
  }

  async respondComplaint(id: string, response: string): Promise<Complaint> {
    const complaint = await this.findComplaintById(id);
    if (complaint.status !== 'PENDENTE') {
      throw new ConflictException('Reclamação não está pendente');
    }
    complaint.response = response;
    complaint.status = 'RESPONDIDA';
    return this.complaintRepo.save(complaint);
  }

  async resolveComplaint(id: string, moderatorNote?: string): Promise<Complaint> {
    const complaint = await this.findComplaintById(id);
    complaint.status = 'RESPONDIDA';
    if (moderatorNote !== undefined) complaint.moderatorNote = moderatorNote;
    return this.complaintRepo.save(complaint);
  }

  async archiveComplaint(id: string): Promise<Complaint> {
    const complaint = await this.findComplaintById(id);
    complaint.status = 'ARQUIVADA';
    return this.complaintRepo.save(complaint);
  }

  async removeComplaint(id: string): Promise<Complaint> {
    const complaint = await this.findComplaintById(id);
    complaint.status = 'REMOVIDA';
    return this.complaintRepo.save(complaint);
  }

  async updateComplaintStatus(
    id: string,
    status: 'PENDENTE' | 'RESPONDIDA' | 'ARQUIVADA' | 'REMOVIDA',
    moderatorNote?: string,
  ): Promise<Complaint> {
    const complaint = await this.findComplaintById(id);
    complaint.status = status;
    if (moderatorNote !== undefined) complaint.moderatorNote = moderatorNote;
    return this.complaintRepo.save(complaint);
  }
}
