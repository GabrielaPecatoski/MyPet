import { EstablishmentService } from "@estab/establishments/application/services/establishment.service";
import { ESTABLISHMENT_REPOSITORY } from "@estab/establishments/domain/repositories/establishment-repository.interface";
import { EstablishmentsController } from "@estab/establishments/infra/controllers/establishments.controller";
import { DrizzleEstablishmentRepository } from "@estab/establishments/infra/repositories/drizzle-establishment.repository";
import { EstablishmentReviewHandler } from "@estab/establishments/infra/messaging/review.handler";
import { ESTAB_SERVICE_REPOSITORY } from "@estab/services/domain/repositories/estab-service-repository.interface";
import { EstabServiceService } from "@estab/services/application/services/estab-service.service";
import { DrizzleEstabServiceRepository } from "@estab/services/infra/repositories/drizzle-estab-service.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [EstablishmentsController],
  providers: [
    EstablishmentService,
    EstabServiceService,
    EstablishmentReviewHandler,
    DrizzleEstablishmentRepository,
    DrizzleEstabServiceRepository,
    { provide: ESTABLISHMENT_REPOSITORY, useExisting: DrizzleEstablishmentRepository },
    { provide: ESTAB_SERVICE_REPOSITORY, useExisting: DrizzleEstabServiceRepository },
  ],
})
export class EstablishmentsModule {}
