import { FaqService } from "@faq/faqs/application/services/faq.service";
import { FAQ_REPOSITORY } from "@faq/faqs/domain/repositories/faq-repository.interface";
import { FaqController } from "@faq/faqs/infra/controllers/faq.controller";
import { DrizzleFaqRepository } from "@faq/faqs/infra/repositories/drizzle-faq.repository";
import { QUESTION_REPOSITORY } from "@faq/questions/domain/repositories/question-repository.interface";
import { DrizzleQuestionRepository } from "@faq/questions/infra/repositories/drizzle-question.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [FaqController],
  providers: [
    FaqService,
    DrizzleFaqRepository,
    DrizzleQuestionRepository,
    { provide: FAQ_REPOSITORY, useExisting: DrizzleFaqRepository },
    { provide: QUESTION_REPOSITORY, useExisting: DrizzleQuestionRepository },
  ],
})
export class FaqModule {}
