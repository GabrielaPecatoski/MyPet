import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { PasswordRecoveryModule } from './password-recovery/password-recovery.module';
import { AuthController } from './auth/auth.controller';

const SERVICE_NAME = 'auth-service';
const SERVICE_PORT = 3001;

@Module({
  imports: [PasswordRecoveryModule],
  controllers: [AppController, AuthController],
  providers: [AppService],
})
export class AppModule {}
