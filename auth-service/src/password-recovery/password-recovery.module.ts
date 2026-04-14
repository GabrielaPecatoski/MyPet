// @ts-ignore
import { Module } from '@nestjs/common';
// @ts-ignore
import { PasswordRecoveryService } from './password-recovery.service';
// @ts-ignore
import { PasswordRecoveryController } from './password-recovery.controller';

@Module({
  controllers: [PasswordRecoveryController],
  providers: [PasswordRecoveryService],
  exports: [PasswordRecoveryService],
})
export class PasswordRecoveryModule {}
