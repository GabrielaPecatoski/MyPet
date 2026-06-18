import type { UserQuestion } from "@faq/questions/domain/models/user-question.entity";

export const QUESTION_REPOSITORY = Symbol("QUESTION_REPOSITORY");

export interface QuestionRepository {
  create(question: UserQuestion): Promise<UserQuestion>;
  update(question: UserQuestion): Promise<void>;
  findById(id: string): Promise<UserQuestion | null>;
  findByUserId(userId: string): Promise<UserQuestion[]>;
  findAll(status?: string): Promise<UserQuestion[]>;
}
