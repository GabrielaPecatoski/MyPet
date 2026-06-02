import { FaqItem } from "@faq/faqs/domain/models/faq-item.entity";
import type { FaqRepository } from "@faq/faqs/domain/repositories/faq-repository.interface";
import { faqItemsSchema } from "@faq/faqs/infra/database/schemas/faq.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { asc, eq, sql } from "drizzle-orm";

@Injectable()
export class DrizzleFaqRepository implements FaqRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(item: FaqItem): Promise<void> {
    await this.drizzleService.db.insert(faqItemsSchema).values({
      question: item.question,
      answer: item.answer,
      category: item.category,
      targetRole: item.targetRole,
      order: item.order,
      active: item.active,
      viewCount: 0,
      createdAt: new Date(),
    });
  }

  async update(item: FaqItem): Promise<void> {
    await this.drizzleService.db
      .update(faqItemsSchema)
      .set({ question: item.question, answer: item.answer, category: item.category, targetRole: item.targetRole, order: item.order, active: item.active, viewCount: item.viewCount })
      .where(eq(faqItemsSchema.id, item.id!));
  }

  async delete(id: string): Promise<void> {
    await this.drizzleService.db.delete(faqItemsSchema).where(eq(faqItemsSchema.id, id));
  }

  async findById(id: string): Promise<FaqItem | null> {
    const [row] = await this.drizzleService.db.select().from(faqItemsSchema).where(eq(faqItemsSchema.id, id)).limit(1);
    return FaqItem.restore(row);
  }

  async findAll(category?: string): Promise<FaqItem[]> {
    const base = this.drizzleService.db.select().from(faqItemsSchema).where(eq(faqItemsSchema.active, true)).orderBy(asc(faqItemsSchema.order));
    const rows = category
      ? await this.drizzleService.db.select().from(faqItemsSchema).where(eq(faqItemsSchema.category, category)).orderBy(asc(faqItemsSchema.order))
      : await base;
    return rows.map((r) => FaqItem.restore(r)!);
  }

  async findAllAdmin(): Promise<FaqItem[]> {
    const rows = await this.drizzleService.db.select().from(faqItemsSchema).orderBy(asc(faqItemsSchema.order));
    return rows.map((r) => FaqItem.restore(r)!);
  }

  async getCategories(): Promise<string[]> {
    const rows = await this.drizzleService.db
      .selectDistinct({ category: faqItemsSchema.category })
      .from(faqItemsSchema)
      .where(eq(faqItemsSchema.active, true));
    return rows.map((r) => r.category).filter(Boolean);
  }
}
