import { Module } from "@nestjs/common";
import { ConfigModule } from "@nestjs/config";
import { ReviewModule } from "@review/review.module";
import { SharedModule } from "@shared/shared.module";

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    SharedModule,
    ReviewModule,
  ],
})
export class AppModule {}
