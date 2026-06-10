import { CreateDriverDto } from "@driver/driver/application/dto/create-driver.dto";
import { DriverService } from "@driver/driver/application/services/driver.service";
import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from "@nestjs/common";
import { ApiOperation, ApiTags } from "@nestjs/swagger";

@ApiTags("Drivers")
@Controller("drivers")
export class DriversController {
  constructor(private readonly driverService: DriverService) {}

  @Post()
  @ApiOperation({ summary: "Registrar motorista (independente ou já associado a um estab)" })
  register(@Body() dto: CreateDriverDto) {
    return this.driverService.register(dto);
  }

  @Get()
  @ApiOperation({ summary: "Listar todos os motoristas" })
  findAll() {
    return this.driverService.findAll();
  }

  @Get("unassociated")
  @ApiOperation({ summary: "Motoristas sem estabelecimento associado" })
  findUnassociated() {
    return this.driverService.findUnassociated();
  }

  @Get("admin/pending")
  @ApiOperation({ summary: "Motoristas aguardando aprovação do admin" })
  findPending() {
    return this.driverService.findPending();
  }

  @Get("by-cpf")
  @ApiOperation({ summary: "Buscar motorista por CPF" })
  findByCpf(@Query("cpf") cpf: string) {
    return this.driverService.findByCpf(cpf);
  }

  @Get("establishment/:establishmentId")
  @ApiOperation({ summary: "Motoristas de um estabelecimento" })
  findByEstablishment(@Param("establishmentId") establishmentId: string) {
    return this.driverService.findByEstablishment(establishmentId);
  }

  @Get(":id")
  @ApiOperation({ summary: "Buscar motorista por id" })
  findOne(@Param("id") id: string) {
    return this.driverService.findById(id);
  }

  @Patch(":id/associate/:establishmentId")
  @ApiOperation({ summary: "Associar motorista a um estabelecimento" })
  associate(
    @Param("id") id: string,
    @Param("establishmentId") establishmentId: string,
  ) {
    return this.driverService.associate(id, establishmentId);
  }

  @Patch(":id/dissociate")
  @ApiOperation({ summary: "Desassociar motorista do estabelecimento" })
  dissociate(@Param("id") id: string) {
    return this.driverService.dissociate(id);
  }

  @Patch(":id/approve")
  @HttpCode(200)
  @ApiOperation({ summary: "Admin aprova motorista (PENDENTE → ATIVO)" })
  approve(@Param("id") id: string) {
    return this.driverService.approve(id);
  }

  @Patch(":id/reject")
  @HttpCode(200)
  @ApiOperation({ summary: "Admin rejeita motorista (→ REJEITADO)" })
  reject(@Param("id") id: string) {
    return this.driverService.reject(id);
  }

  @Patch(":id/deactivate")
  @HttpCode(200)
  @ApiOperation({ summary: "Desativar motorista" })
  deactivate(@Param("id") id: string) {
    return this.driverService.deactivate(id);
  }

  @Patch(":id/activate")
  @HttpCode(200)
  @ApiOperation({ summary: "Reativar motorista" })
  activate(@Param("id") id: string) {
    return this.driverService.activate(id);
  }

  @Delete(":id")
  @HttpCode(204)
  remove(@Param("id") id: string) {
    return this.driverService.remove(id);
  }
}
