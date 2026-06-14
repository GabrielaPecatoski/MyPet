import { CreateEstablishmentDto } from "@estab/establishments/application/dto/create-establishment.dto";
import { EstablishmentDto } from "@estab/establishments/application/dto/establishment.dto";
import { UpdateEstablishmentDto } from "@estab/establishments/application/dto/update-establishment.dto";
import { EstablishmentService } from "@estab/establishments/application/services/establishment.service";
import { CreateServiceDto } from "@estab/services/application/dto/create-service.dto";
import { EstabServiceService } from "@estab/services/application/services/estab-service.service";
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
  Query,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiNotFoundResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import { HateoasItem } from "@shared/infra/hateoas";

@ApiTags("establishments")
@Controller("establishments")
export class EstablishmentsController {
  constructor(
    private readonly establishmentService: EstablishmentService,
    private readonly serviceService: EstabServiceService,
  ) {}

  @Get()
  @Public()
  @ApiOperation({ summary: "Listar estabelecimentos" })
  @ApiQuery({ name: "search", required: false })
  async findAll(@Query("search") search?: string): Promise<EstablishmentDto[]> {
    return this.establishmentService.findAll(search);
  }

  @Get("emergency")
  @Public()
  @ApiOperation({
    summary: "Listar estabelecimentos que atendem emergências veterinárias",
  })
  async findByEmergency(): Promise<EstablishmentDto[]> {
    return this.establishmentService.findByEmergency();
  }

  @Get("admin/all")
  @ApiBearerAuth()
  @RequirePermissions(Permission.ADMIN_READ)
  @ApiOperation({
    summary: "Listar estabelecimentos com contagem de serviços (admin)",
  })
  async findAllAdmin() {
    return this.establishmentService.findAllAdmin();
  }

  @Get("owner/:ownerId")
  @ApiBearerAuth()
  @RequirePermissions(Permission.ESTABLISHMENTS_READ)
  @ApiOperation({ summary: "Listar estabelecimentos do proprietário" })
  async findByOwner(
    @Param("ownerId") ownerId: string,
  ): Promise<EstablishmentDto[]> {
    return this.establishmentService.findByOwnerId(ownerId);
  }

  @Get(":id")
  @Public()
  @ApiOperation({ summary: "Buscar estabelecimento por ID" })
  @ApiNotFoundResponse({ description: "Estabelecimento não encontrado" })
  @HateoasItem<EstablishmentDto>({
    basePath: "/v1/establishments",
    itemLinks: (item) => ({
      self: { href: `/v1/establishments/${item.id}`, method: "GET" },
      update: { href: `/v1/establishments/${item.id}`, method: "PATCH" },
      services: {
        href: `/v1/establishments/${item.id}/services`,
        method: "GET",
      },
    }),
  })
  async findById(@Param("id") id: string) {
    return this.establishmentService.findById(id);
  }

  @Post()
  @ApiBearerAuth()
  @RequirePermissions(Permission.ESTABLISHMENTS_WRITE)
  @ApiOperation({ summary: "Criar estabelecimento" })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateEstablishmentDto,
  ) {
    return this.establishmentService.create(user.sub, body);
  }

  @Post("owner/:ownerId")
  @ApiBearerAuth()
  @RequirePermissions(Permission.ESTABLISHMENTS_WRITE)
  @ApiOperation({
    summary: "Criar estabelecimento para proprietário específico",
  })
  async createForOwner(
    @Param("ownerId") ownerId: string,
    @Body() body: CreateEstablishmentDto,
  ) {
    return this.establishmentService.create(ownerId, body);
  }

  @Patch(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ESTABLISHMENTS_WRITE)
  @ApiOperation({ summary: "Atualizar estabelecimento" })
  @ApiNoContentResponse({ description: "Estabelecimento atualizado" })
  async update(@Param("id") id: string, @Body() body: UpdateEstablishmentDto) {
    return this.establishmentService.update(id, body);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.ESTABLISHMENTS_DELETE)
  @ApiOperation({ summary: "Remover estabelecimento" })
  @ApiNoContentResponse({ description: "Estabelecimento removido" })
  async remove(@Param("id") id: string) {
    return this.establishmentService.remove(id);
  }

  @Get(":id/services")
  @Public()
  @ApiOperation({ summary: "Listar serviços do estabelecimento" })
  async listServices(@Param("id") id: string) {
    return this.serviceService.findByEstablishment(id);
  }

  @Post(":id/services")
  @ApiBearerAuth()
  @RequirePermissions(Permission.SERVICES_WRITE)
  @ApiOperation({ summary: "Adicionar serviço ao estabelecimento" })
  async addService(@Param("id") id: string, @Body() body: CreateServiceDto) {
    return this.serviceService.addService(id, body);
  }

  @Delete(":id/services/:serviceId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.SERVICES_DELETE)
  @ApiOperation({ summary: "Remover serviço do estabelecimento" })
  @ApiNoContentResponse({ description: "Serviço removido" })
  async removeService(
    @Param("id") _id: string,
    @Param("serviceId") serviceId: string,
  ) {
    return this.serviceService.removeService(serviceId);
  }
}
