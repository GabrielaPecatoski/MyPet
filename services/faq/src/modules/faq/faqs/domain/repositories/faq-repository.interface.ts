import type { FaqItem } from "@faq/faqs/domain/models/faq-item.entity";

export const FAQ_REPOSITORY = Symbol("FAQ_REPOSITORY");

export interface FaqRepository {
  create(item: FaqItem): Promise<void>;
  update(item: FaqItem): Promise<void>;
  delete(id: string): Promise<void>;
  findById(id: string): Promise<FaqItem | null>;
  findAll(category?: string): Promise<FaqItem[]>;
  findAllAdmin(): Promise<FaqItem[]>;
  getCategories(): Promise<string[]>;
}
