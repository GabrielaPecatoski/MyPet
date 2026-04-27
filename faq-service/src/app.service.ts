import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  // ── FAQ Items ─────────────────────────────────────────────────────

  findActiveFaqs(category?: string) {
    return this.prisma.faqItem.findMany({
      where: {
        active: true,
        ...(category ? { category } : {}),
      },
      orderBy: [{ category: 'asc' }, { order: 'asc' }],
    });
  }

  async getCategories() {
    const items = await this.prisma.faqItem.findMany({
      where: { active: true },
      select: { category: true },
      distinct: ['category'],
      orderBy: { category: 'asc' },
    });
    return items.map((i) => i.category);
  }

  findAllFaqs() {
    return this.prisma.faqItem.findMany({
      orderBy: [{ category: 'asc' }, { order: 'asc' }],
    });
  }

  createFaq(data: {
    question: string;
    answer: string;
    category?: string;
    order?: number;
  }) {
    return this.prisma.faqItem.create({
      data: {
        question: data.question,
        answer: data.answer,
        category: data.category ?? 'Geral',
        order: data.order ?? 0,
        active: true,
      },
    });
  }

  async updateFaq(
    id: string,
    data: {
      question?: string;
      answer?: string;
      category?: string;
      order?: number;
      active?: boolean;
    },
  ) {
    await this.ensureFaqExists(id);
    return this.prisma.faqItem.update({ where: { id }, data });
  }

  async deleteFaq(id: string) {
    await this.ensureFaqExists(id);
    await this.prisma.faqItem.delete({ where: { id } });
    return { deleted: true };
  }

  // ── User Questions ────────────────────────────────────────────────

  submitQuestion(data: {
    userId: string;
    userName: string;
    userRole: string;
    question: string;
  }) {
    return this.prisma.userQuestion.create({
      data: {
        userId: data.userId,
        userName: data.userName,
        userRole: data.userRole ?? 'CLIENTE',
        question: data.question,
        status: 'PENDENTE',
      },
    });
  }

  getUserQuestions(userId: string) {
    return this.prisma.userQuestion.findMany({
      where: { userId },
      orderBy: { createdAt: 'desc' },
    });
  }

  getAllQuestions(status?: string) {
    return this.prisma.userQuestion.findMany({
      where: status ? { status } : undefined,
      orderBy: { createdAt: 'desc' },
    });
  }

  async answerQuestion(id: string, answer: string) {
    await this.ensureQuestionExists(id);
    return this.prisma.userQuestion.update({
      where: { id },
      data: {
        answer,
        status: 'RESPONDIDA',
        answeredAt: new Date(),
      },
    });
  }

  async closeQuestion(id: string) {
    await this.ensureQuestionExists(id);
    return this.prisma.userQuestion.update({
      where: { id },
      data: { status: 'FECHADA' },
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────

  private async ensureFaqExists(id: string) {
    const item = await this.prisma.faqItem.findUnique({ where: { id } });
    if (!item) throw new NotFoundException('FAQ não encontrado');
    return item;
  }

  private async ensureQuestionExists(id: string) {
    const q = await this.prisma.userQuestion.findUnique({ where: { id } });
    if (!q) throw new NotFoundException('Pergunta não encontrada');
    return q;
  }
}
