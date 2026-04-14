// @ts-ignore
import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { RegistrationModule } from './registration/registration.module';
import { EstablishmentProfileModule } from './profile/profile.module';

const SERVICE_NAME = 'establishment-service';
const SERVICE_PORT = 3003;

@Module({
  imports: [RegistrationModule, EstablishmentProfileModule],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
