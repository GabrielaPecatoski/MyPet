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
import { ApiOperation, ApiTags } from "@nestjs/swagger";
import {
  CreateVeterinarianDto,
  UpdateVetAvailabilityDto,
} from "@vet/vet/application/dto/create-veterinarian.dto";
import { CreateEmergencyCallDto } from "@vet/vet/application/dto/emergency-call.dto";
import { VeterinarianService } from "@vet/vet/application/services/veterinarian.service";

@ApiTags("Veterinarians")
@Controller("veterinarians")
export class VeterinariansController {
  constructor(private readonly vetService: VeterinarianService) {}

  @Post()
  @ApiOperation({ summary: "Registrar veterinário" })
  register(@Body() dto: CreateVeterinarianDto) {
    return this.vetService.register(dto);
  }

  @Get()
  @ApiOperation({ summary: "Listar todos os veterinários" })
  findAll() {
    return this.vetService.findAll();
  }

  @Get("unassociated")
  @ApiOperation({ summary: "Veterinários sem estabelecimento" })
  findUnassociated() {
    return this.vetService.findUnassociated();
  }

  @Get("available")
  @ApiOperation({ summary: "Veterinários aprovados e disponíveis" })
  findAvailable() {
    return this.vetService.findAvailable();
  }

  @Get("admin/pending")
  @ApiOperation({ summary: "Veterinários aguardando aprovação" })
  findPending() {
    return this.vetService.findPending();
  }

  @Get("by-cpf")
  @ApiOperation({ summary: "Buscar por CPF" })
  findByCpf(@Query("cpf") cpf: string) {
    return this.vetService.findByCpf(cpf);
  }

  @Get("establishment/:establishmentId")
  @ApiOperation({ summary: "Veterinários de um estabelecimento" })
  findByEstablishment(@Param("establishmentId") establishmentId: string) {
    return this.vetService.findByEstablishment(establishmentId);
  }

  @Post(":vetId/emergency-call")
  @ApiOperation({ summary: "Cliente dispara chamado de emergência para o vet" })
  createEmergencyCall(
    @Param("vetId") vetId: string,
    @Body() dto: CreateEmergencyCallDto,
  ) {
    return this.vetService.createEmergencyCall(vetId, dto);
  }

  @Get(":vetId/emergency-calls/pending")
  @ApiOperation({ summary: "Vet consulta chamados de emergência pendentes" })
  getPendingEmergencyCalls(@Param("vetId") vetId: string) {
    return this.vetService.getPendingEmergencyCalls(vetId);
  }

  @Patch("emergency-calls/:callId/acknowledge")
  @HttpCode(204)
  @ApiOperation({ summary: "Vet reconhece / descarta chamado de emergência" })
  acknowledgeEmergencyCall(@Param("callId") callId: string) {
    return this.vetService.acknowledgeEmergencyCall(callId);
  }

  @Get(":id")
  @ApiOperation({ summary: "Buscar por id" })
  findOne(@Param("id") id: string) {
    return this.vetService.findById(id);
  }

  @Patch(":id/associate/:establishmentId")
  @ApiOperation({ summary: "Associar ao estabelecimento" })
  associate(
    @Param("id") id: string,
    @Param("establishmentId") establishmentId: string,
  ) {
    return this.vetService.associate(id, establishmentId);
  }

  @Patch(":id/dissociate")
  @ApiOperation({ summary: "Desassociar do estabelecimento" })
  dissociate(@Param("id") id: string) {
    return this.vetService.dissociate(id);
  }

  @Patch(":id/approve")
  @HttpCode(200)
  @ApiOperation({ summary: "Admin aprova veterinário" })
  approve(@Param("id") id: string) {
    return this.vetService.approve(id);
  }

  @Patch(":id/reject")
  @HttpCode(200)
  @ApiOperation({ summary: "Admin rejeita veterinário" })
  reject(@Param("id") id: string) {
    return this.vetService.reject(id);
  }

  @Patch(":id/availability")
  @HttpCode(200)
  @ApiOperation({ summary: "Atualizar disponibilidade" })
  updateAvailability(
    @Param("id") id: string,
    @Body() dto: UpdateVetAvailabilityDto,
  ) {
    return this.vetService.updateAvailability(id, dto);
  }

  @Patch(":id/deactivate")
  @HttpCode(200)
  @ApiOperation({ summary: "Desativar veterinário" })
  deactivate(@Param("id") id: string) {
    return this.vetService.deactivate(id);
  }

  @Patch(":id/activate")
  @HttpCode(200)
  @ApiOperation({ summary: "Reativar veterinário" })
  activate(@Param("id") id: string) {
    return this.vetService.activate(id);
  }

  @Delete(":id")
  @HttpCode(204)
  remove(@Param("id") id: string) {
    return this.vetService.remove(id);
  }
}
