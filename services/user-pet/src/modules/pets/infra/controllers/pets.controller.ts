import { CreatePetDto } from "@pets/pets/application/dto/create-pet.dto";
import { PetDto } from "@pets/pets/application/dto/pet.dto";
import { UpdatePetDto } from "@pets/pets/application/dto/update-pet.dto";
import { PetService } from "@pets/pets/application/services/pet.service";
import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";
import { HateoasItem } from "@shared/infra/hateoas";

@ApiTags("pets")
@ApiBearerAuth()
@Controller("pets")
export class PetsController {
  constructor(private readonly petService: PetService) {}

  @Post()
  @RequirePermissions(Permission.PETS_WRITE)
  @ApiOperation({ summary: "Cadastrar pet do usuário autenticado" })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreatePetDto,
  ) {
    return this.petService.create(user.sub, body);
  }

  @Post("user/:userId")
  @RequirePermissions(Permission.PETS_WRITE)
  @ApiOperation({ summary: "Cadastrar pet para um usuário específico" })
  async createForUser(
    @Param("userId") userId: string,
    @Body() body: CreatePetDto,
  ) {
    return this.petService.create(userId, body);
  }

  @Get("user/:userId")
  @RequirePermissions(Permission.PETS_READ)
  @ApiOperation({ summary: "Listar pets de um usuário" })
  async findByUser(@Param("userId") userId: string): Promise<PetDto[]> {
    return this.petService.findByUserId(userId);
  }

  @Get(":id")
  @RequirePermissions(Permission.PETS_READ)
  @ApiOperation({ summary: "Buscar pet por ID" })
  @ApiNotFoundResponse({ description: "Pet não encontrado" })
  @HateoasItem<PetDto>({
    basePath: "/v1/pets",
    itemLinks: (item) => ({
      self: { href: `/v1/pets/${item.id}`, method: "GET" },
      update: { href: `/v1/pets/${item.id}`, method: "PATCH" },
      delete: { href: `/v1/pets/${item.id}`, method: "DELETE" },
      owner: { href: `/v1/users/${item.userId}`, method: "GET" },
    }),
  })
  async findById(@Param("id") id: string) {
    return this.petService.findById(id);
  }

  @Patch(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.PETS_WRITE)
  @ApiOperation({ summary: "Atualizar pet" })
  @ApiNoContentResponse({ description: "Pet atualizado" })
  async update(@Param("id") id: string, @Body() body: UpdatePetDto) {
    return this.petService.update(id, body);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.PETS_DELETE)
  @ApiOperation({ summary: "Remover pet" })
  @ApiNoContentResponse({ description: "Pet removido" })
  async remove(@Param("id") id: string) {
    return this.petService.remove(id);
  }
}
