// @ts-ignore
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UsersModule } from './users/users.module';
import { PetsModule } from './pets/pets.module';

const SERVICE_NAME = 'user-pet-service';
const SERVICE_PORT = 3002;    

@Module({
  imports: [UsersModule, PetsModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
