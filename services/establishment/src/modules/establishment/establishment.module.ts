import { Module } from "@nestjs/common";
import { EstablishmentsModule } from "./establishments/establishments.module";
import { VeterinariansModule } from "./veterinarians/veterinarians.module";

@Module({
  imports: [EstablishmentsModule, VeterinariansModule],
})
export class EstablishmentModule {}
