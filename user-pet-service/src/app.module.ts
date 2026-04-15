import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { TypeOrmModule } from '@nestjs/typeorm';
import { PetModule } from './pet/pet.module';
import { HealthController } from './health/health.controller';
import { ConsulService } from './consul/consul.service';
import { Pet } from './pet/entities/pet.entity';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    TypeOrmModule.forRoot({
      type: 'postgres',
      url: process.env.DATABASE_URL,
      entities: [Pet],
      synchronize: true,
      ssl: false,
    }),
    PetModule,
  ],
  controllers: [HealthController],
  providers: [
    {
      provide: ConsulService,
      useValue: new ConsulService({ serviceName: 'user-pet-service', servicePort: 3002 }),
    },
  ],
})
export class AppModule {}
