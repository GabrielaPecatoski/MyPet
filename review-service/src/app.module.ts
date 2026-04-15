import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ReviewModule } from './review/review.module';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { Review } from './review/entities/review.entity';
import { Complaint } from './review/entities/complaint.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [Review, Complaint],
      synchronize: true,
      ssl: false,
    }),
    ReviewModule,
  ],
  controllers: [HealthController],
  providers: [{
    provide: ConsulService,
    useValue: new ConsulService({ serviceName: 'review-service', servicePort: 3007 }),
  }],
})
export class AppModule {}
