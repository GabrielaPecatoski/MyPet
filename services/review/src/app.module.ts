import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { SharedModule } from "@shared/shared.module";
import { ReviewModule } from "@review/review.module";

@Module({
  imports: [ConfigModule.forRoot({ isGlobal: true }), SharedModule, ReviewModule],
})
export class AppModule {}
