import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';

const SERVICE_NAME = 'establishment-service';
const SERVICE_PORT = 3003;

@Module({
  imports: [],
  controllers: [AppController],
  providers: [AppService],
})
export class AppModule {}
