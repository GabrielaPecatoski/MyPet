import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { PetsModule } from "@pets/pets/pets.module";
import { SharedModule } from "@shared/shared.module";

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), SharedModule, PetsModule],
})
export class AppModule {}
