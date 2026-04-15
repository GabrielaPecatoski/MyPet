import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Review } from './entities/review.entity';
import { Complaint } from './entities/complaint.entity';
import { ReviewController } from './review.controller';
import { ReviewService } from './review.service';

@Module({
  imports: [TypeOrmModule.forFeature([Review, Complaint])],
  controllers: [ReviewController],
  providers: [ReviewService],
})
export class ReviewModule {}
