// @ts-ignore
import { Module } from '@nestjs/common';
// @ts-ignore
import { PetsService } from './pets.service';
// @ts-ignore
import { PetsController } from './pets.controller';

@Module({
  controllers: [PetsController],
  providers: [PetsService],
  exports: [PetsService],
})
export class PetsModule {}
