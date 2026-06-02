import { AuthService } from "@auth/users/application/services/auth.service";
import { UserService } from "@auth/users/application/services/user.service";
import { USER_REPOSITORY } from "@auth/users/domain/repositories/user-repository.interface";
import { AuthController } from "@auth/users/infra/controllers/auth.controller";
import { UsersController } from "@auth/users/infra/controllers/users.controller";
import { DrizzleUserRepository } from "@auth/users/infra/repositories/drizzle-user.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [AuthController, UsersController],
  providers: [
    AuthService,
    UserService,
    DrizzleUserRepository,
    {
      provide: USER_REPOSITORY,
      useExisting: DrizzleUserRepository,
    },
  ],
})
export class UsersModule {}
