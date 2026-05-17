import { UserQuestion, type QuestionStatus } from "@faq/questions/domain/models/user-question.entity";
import type { QuestionRepository } from "@faq/questions/domain/repositories/question-repository.interface";
import { userQuestionsSchema } from "@faq/questions/infra/database/schemas/question.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DrizzleQuestionRepository implements QuestionRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(q: UserQuestion): Promise<void> {
    await this.drizzleService.db.insert(userQuestionsSchema).values({
      userId: q.userId,
      userName: q.userName,
      userRole: q.userRole,
      question: q.question,
      answer: q.answer,
      status: q.status,
      createdAt: new Date(),
      answeredAt: q.answeredAt,
    });
  }

  async update(q: UserQuestion): Promise<void> {
    await this.drizzleService.db
      .update(userQuestionsSchema)
      .set({ answer: q.answer, status: q.status, answeredAt: q.answeredAt })
      .where(eq(userQuestionsSchema.id, q.id!));
  }

  async findById(id: string): Promise<UserQuestion | null> {
    const [row] = await this.drizzleService.db.select().from(userQuestionsSchema).where(eq(userQuestionsSchema.id, id)).limit(1);
    return row ? UserQuestion.restore({ ...row, status: row.status as QuestionStatus }) : null;
  }

  async findByUserId(userId: string): Promise<UserQuestion[]> {
    const rows = await this.drizzleService.db.select().from(userQuestionsSchema).where(eq(userQuestionsSchema.userId, userId));
    return rows.map((r) => UserQuestion.restore({ ...r, status: r.status as QuestionStatus })!);
  }

  async findAll(status?: string): Promise<UserQuestion[]> {
    const rows = status
      ? await this.drizzleService.db.select().from(userQuestionsSchema).where(eq(userQuestionsSchema.status, status))
      : await this.drizzleService.db.select().from(userQuestionsSchema);
    return rows.map((r) => UserQuestion.restore({ ...r, status: r.status as QuestionStatus })!);
  }
}
