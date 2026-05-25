import { Module } from "@nestjs/common";
import { EstablishmentsModule } from "./establishments/establishments.module";

@Module({
  imports: [EstablishmentsModule],
})
export class EstablishmentModule {}
