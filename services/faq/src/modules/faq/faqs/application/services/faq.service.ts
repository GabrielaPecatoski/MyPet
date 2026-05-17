import { FaqItem } from "@faq/faqs/domain/models/faq-item.entity";
import { FAQ_REPOSITORY, type FaqRepository } from "@faq/faqs/domain/repositories/faq-repository.interface";
import { QUESTION_REPOSITORY, type QuestionRepository } from "@faq/questions/domain/repositories/question-repository.interface";
import { UserQuestion } from "@faq/questions/domain/models/user-question.entity";
import { Inject, Injectable, NotFoundException } from "@nestjs/common";

export interface CreateFaqDto { question: string; answer: string; category?: string; targetRole?: string; order?: number; }
export interface CreateQuestionDto { question: string; userName: string; userRole?: string; }

@Injectable()
export class FaqService {
  constructor(
    @Inject(FAQ_REPOSITORY) private readonly faqRepo: FaqRepository,
    @Inject(QUESTION_REPOSITORY) private readonly questionRepo: QuestionRepository,
  ) {}

  async createFaq(dto: CreateFaqDto): Promise<void> {
    const item = FaqItem.restore({
      question: dto.question,
      answer: dto.answer,
      category: dto.category ?? "",
      targetRole: dto.targetRole ?? "CLIENTE",
      order: dto.order ?? 0,
      active: true,
      viewCount: 0,
    })!;
    await this.faqRepo.create(item);
  }

  async listFaq(category?: string) {
    return this.faqRepo.findAll(category);
  }

  async listFaqAdmin() {
    return this.faqRepo.findAllAdmin();
  }

  async getCategories() {
    return this.faqRepo.getCategories();
  }

  async updateFaq(id: string, dto: Partial<CreateFaqDto>): Promise<void> {
    const item = await this.faqRepo.findById(id);
    if (!item) throw new NotFoundException("FAQ não encontrado");
    if (dto.question) item.withQuestion(dto.question);
    if (dto.answer) item.withAnswer(dto.answer);
    if (dto.category !== undefined) item.withCategory(dto.category);
    if (dto.targetRole) item.withTargetRole(dto.targetRole);
    if (dto.order !== undefined) item.withOrder(dto.order);
    await this.faqRepo.update(item);
  }

  async deleteFaq(id: string): Promise<void> {
    const item = await this.faqRepo.findById(id);
    if (!item) throw new NotFoundException("FAQ não encontrado");
    await this.faqRepo.delete(id);
  }

  async incrementViewCount(id: string): Promise<void> {
    const item = await this.faqRepo.findById(id);
    if (!item) throw new NotFoundException("FAQ não encontrado");
    item.incrementViewCount();
    await this.faqRepo.update(item);
  }

  async submitQuestion(userId: string, dto: CreateQuestionDto): Promise<void> {
    const q = UserQuestion.restore({
      userId,
      userName: dto.userName,
      userRole: dto.userRole ?? "CLIENTE",
      question: dto.question,
      status: "PENDENTE",
    })!;
    await this.questionRepo.create(q);
  }

  async listQuestions(status?: string) {
    return this.questionRepo.findAll(status);
  }

  async listUserQuestions(userId: string) {
    return this.questionRepo.findByUserId(userId);
  }

  async answerQuestion(id: string, answer: string): Promise<void> {
    const q = await this.questionRepo.findById(id);
    if (!q) throw new NotFoundException("Pergunta não encontrada");
    q.withAnswer(answer);
    await this.questionRepo.update(q);
  }

  async closeQuestion(id: string): Promise<void> {
    const q = await this.questionRepo.findById(id);
    if (!q) throw new NotFoundException("Pergunta não encontrada");
    q.close();
    await this.questionRepo.update(q);
  }
}
