import { CreateUserDto } from "@auth/users/application/dto/create-user.dto";
import { LoginDto } from "@auth/users/application/dto/login.dto";
import { UserDto } from "@auth/users/application/dto/user.dto";
import { AuthService } from "@auth/users/application/services/auth.service";
import { UserService } from "@auth/users/application/services/user.service";
import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Patch, Post } from "@nestjs/common";
import { UpdateUserDto } from "@auth/users/application/dto/update-user.dto";
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
  ApiUnauthorizedResponse,
} from "@nestjs/swagger";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";

@ApiTags("auth")
@Controller("auth")
export class AuthController {
  constructor(
    private readonly authService: AuthService,
    private readonly userService: UserService,
  ) {}

  @Post("register")
  @Public()
  @ApiOperation({ summary: "Registrar novo usuário" })
  async register(@Body() body: CreateUserDto) {
    return this.authService.register(body);
  }

  @Post("login")
  @Public()
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: "Autenticar usuário" })
  @ApiUnauthorizedResponse({ description: "Credenciais inválidas" })
  async login(@Body() body: LoginDto) {
    return this.authService.login(body);
  }

  @Get("me")
  @ApiBearerAuth()
  @ApiOperation({ summary: "Retornar usuário autenticado" })
  async me(@CurrentUser() user: AuthenticatedUser): Promise<UserDto | null> {
    return this.userService.findById(user.sub);
  }

  @Patch("me")
  @ApiBearerAuth()
  @ApiOperation({ summary: "Atualizar o próprio perfil" })
  async updateMe(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: UpdateUserDto,
  ): Promise<UserDto | null> {
    await this.userService.update(user.sub, body);
    return this.userService.findById(user.sub);
  }

  @Delete("me")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @ApiOperation({ summary: "Excluir a própria conta" })
  async deleteMe(@CurrentUser() user: AuthenticatedUser): Promise<void> {
    await this.userService.remove(user.sub);
  }
}
