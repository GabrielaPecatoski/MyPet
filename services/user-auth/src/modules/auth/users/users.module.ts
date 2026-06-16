import { AuthService } from "@auth/users/application/services/auth.service";
import { UserService } from "@auth/users/application/services/user.service";
import { PASSWORD_RESET_TOKEN_REPOSITORY } from "@auth/users/domain/repositories/password-reset-token-repository.interface";
import { USER_REPOSITORY } from "@auth/users/domain/repositories/user-repository.interface";
import { AuthController } from "@auth/users/infra/controllers/auth.controller";
import { UsersController } from "@auth/users/infra/controllers/users.controller";
import { EmailService } from "@auth/users/infra/email/email.service";
import { DrizzlePasswordResetTokenRepository } from "@auth/users/infra/repositories/drizzle-password-reset-token.repository";
import { DrizzleUserRepository } from "@auth/users/infra/repositories/drizzle-user.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [AuthController, UsersController],
  providers: [
    AuthService,
    UserService,
    EmailService,
    DrizzleUserRepository,
    DrizzlePasswordResetTokenRepository,
    {
      provide: USER_REPOSITORY,
      useExisting: DrizzleUserRepository,
    },
    {
      provide: PASSWORD_RESET_TOKEN_REPOSITORY,
      useExisting: DrizzlePasswordResetTokenRepository,
    },
  ],
})
export class UsersModule {}
