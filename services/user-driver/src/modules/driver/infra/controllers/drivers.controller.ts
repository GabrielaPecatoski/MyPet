import {
  CreateDriverDto,
  SetDriverOnlineDto,
  UpdateDriverPhotoDto,
} from "@driver/driver/application/dto/create-driver.dto";
import { DriverService } from "@driver/driver/application/services/driver.service";
import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  Param,
  Patch,
  Post,
  Query,
} from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";

@ApiTags("Drivers")
@ApiBearerAuth()
@Controller("drivers")
export class DriversController {
  constructor(private readonly driverService: DriverService) {}

  @Post()
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @ApiOperation({
    summary: "Registrar motorista (independente ou já associado a um estab)",
  })
  register(@Body() dto: CreateDriverDto) {
    return this.driverService.register(dto);
  }

  @Get()
  @RequirePermissions(Permission.DRIVERS_READ)
  @ApiOperation({ summary: "Listar todos os motoristas" })
  findAll() {
    return this.driverService.findAll();
  }

  @Get("unassociated")
  @RequirePermissions(Permission.DRIVERS_READ)
  @ApiOperation({ summary: "Motoristas sem estabelecimento associado" })
  findUnassociated() {
    return this.driverService.findUnassociated();
  }

  @Get("available")
  @RequirePermissions(Permission.DRIVERS_READ)
  @ApiOperation({ summary: "Motoristas ativos e online" })
  findAvailable() {
    return this.driverService.findAvailable();
  }

  @Get("admin/pending")
  @RequirePermissions(Permission.ADMIN_WRITE)
  @ApiOperation({ summary: "Motoristas aguardando aprovação do admin" })
  findPending() {
    return this.driverService.findPending();
  }

  @Get("by-cpf")
  @RequirePermissions(Permission.DRIVERS_READ)
  @ApiOperation({ summary: "Buscar motorista por CPF" })
  findByCpf(@Query("cpf") cpf: string) {
    return this.driverService.findByCpf(cpf);
  }

  @Get("establishment/:establishmentId")
  @RequirePermissions(Permission.DRIVERS_READ)
  @ApiOperation({ summary: "Motoristas de um estabelecimento" })
  findByEstablishment(@Param("establishmentId") establishmentId: string) {
    return this.driverService.findByEstablishment(establishmentId);
  }

  @Get(":id")
  @RequirePermissions(Permission.DRIVERS_READ)
  @ApiOperation({ summary: "Buscar motorista por id" })
  findOne(@Param("id") id: string) {
    return this.driverService.findById(id);
  }

  @Patch(":id/associate/:establishmentId")
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @ApiOperation({ summary: "Associar motorista a um estabelecimento" })
  associate(
    @Param("id") id: string,
    @Param("establishmentId") establishmentId: string,
  ) {
    return this.driverService.associate(id, establishmentId);
  }

  @Patch(":id/dissociate")
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @ApiOperation({ summary: "Desassociar motorista do estabelecimento" })
  dissociate(@Param("id") id: string) {
    return this.driverService.dissociate(id);
  }

  @Patch(":id/approve")
  @RequirePermissions(Permission.ADMIN_WRITE)
  @HttpCode(200)
  @ApiOperation({ summary: "Admin aprova motorista (PENDENTE → ATIVO)" })
  approve(@Param("id") id: string) {
    return this.driverService.approve(id);
  }

  @Patch(":id/reject")
  @RequirePermissions(Permission.ADMIN_WRITE)
  @HttpCode(200)
  @ApiOperation({ summary: "Admin rejeita motorista (→ REJEITADO)" })
  reject(@Param("id") id: string) {
    return this.driverService.reject(id);
  }

  @Patch(":id/photo")
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @HttpCode(200)
  @ApiOperation({ summary: "Atualizar foto de perfil do motorista" })
  updatePhoto(@Param("id") id: string, @Body() dto: UpdateDriverPhotoDto) {
    return this.driverService.updatePhoto(id, dto);
  }

  @Patch(":id/online")
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @HttpCode(200)
  @ApiOperation({ summary: "Definir disponibilidade (online/offline) do motorista" })
  setOnline(@Param("id") id: string, @Body() dto: SetDriverOnlineDto) {
    return this.driverService.setOnline(id, dto.online);
  }

  @Patch(":id/deactivate")
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @HttpCode(200)
  @ApiOperation({ summary: "Desativar motorista" })
  deactivate(@Param("id") id: string) {
    return this.driverService.deactivate(id);
  }

  @Patch(":id/activate")
  @RequirePermissions(Permission.DRIVERS_WRITE)
  @HttpCode(200)
  @ApiOperation({ summary: "Reativar motorista" })
  activate(@Param("id") id: string) {
    return this.driverService.activate(id);
  }

  @Delete(":id")
  @RequirePermissions(Permission.DRIVERS_DELETE)
  @HttpCode(204)
  remove(@Param("id") id: string) {
    return this.driverService.remove(id);
  }
}
