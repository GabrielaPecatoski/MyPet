import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { EstablishmentModule } from './establishment/establishment.module';
import { Establishment } from './establishment/entities/establishment.entity';
import { EstablishmentServiceItem } from './establishment/entities/establishment-service-item.entity';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL ?? 'postgresql://postgres:root@localhost:5432/mypet',
      entities: [Establishment, EstablishmentServiceItem],
      synchronize: true,
      ssl: false,
    }),
    EstablishmentModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: ConsulService,
      useValue: new ConsulService({ serviceName: 'establishment-service', servicePort: 3003 }),
    },
  ],
})
export class AppModule {}
