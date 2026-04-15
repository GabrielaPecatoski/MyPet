import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Establishment } from './entities/establishment.entity';
import { EstablishmentServiceItem } from './entities/establishment-service-item.entity';
import { EstablishmentService } from './establishment.service';
import { EstablishmentController } from './establishment.controller';

@Module({
  imports: [TypeOrmModule.forFeature([Establishment, EstablishmentServiceItem])],
  controllers: [EstablishmentController],
  providers: [EstablishmentService],
})
export class EstablishmentModule {}
