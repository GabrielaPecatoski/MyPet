// @ts-ignore
import { Module } from '@nestjs/common';
import { EstablishmentProfileService } from './profile.service';
import { EstablishmentProfileController } from './profile.controller';

@Module({
  controllers: [EstablishmentProfileController],
  providers: [EstablishmentProfileService],
  exports: [EstablishmentProfileService],
})
export class EstablishmentProfileModule {}
