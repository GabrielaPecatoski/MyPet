import { CreateVeterinarianDto } from '@estab/veterinarians/application/dto/create-veterinarian.dto';
import { VeterinarianService } from '@estab/veterinarians/application/services/veterinarian.service';
import { Body, Controller, Delete, Get, HttpCode, Param, Patch, Post, Query } from '@nestjs/common';
import { ApiOperation, ApiTags } from '@nestjs/swagger';

@ApiTags('Veterinarians')
@Controller('veterinarians')
export class VeterinariansController {
  constructor(private readonly vetService: VeterinarianService) {}

  @Post()
  @ApiOperation({ summary: 'Registrar veterinário (independente ou já associado a um estab)' })
  register(@Body() dto: CreateVeterinarianDto) {
    return this.vetService.register(dto);
  }

  @Get()
  @ApiOperation({ summary: 'Listar todos os veterinários' })
  findAll() {
    return this.vetService.findAll();
  }

  @Get('unassociated')
  @ApiOperation({ summary: 'Veterinários sem estabelecimento associado' })
  findUnassociated() {
    return this.vetService.findUnassociated();
  }

  @Get('by-cpf')
  @ApiOperation({ summary: 'Buscar veterinário por CPF' })
  findByCpf(@Query('cpf') cpf: string) {
    return this.vetService.findByCpf(cpf);
  }

  @Get('establishment/:establishmentId')
  @ApiOperation({ summary: 'Veterinários de um estabelecimento' })
  findByEstablishment(@Param('establishmentId') establishmentId: string) {
    return this.vetService.findByEstablishment(establishmentId);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Buscar veterinário por id' })
  findOne(@Param('id') id: string) {
    return this.vetService.findById(id);
  }

  @Patch(':id/associate/:establishmentId')
  @ApiOperation({ summary: 'Associar veterinário a um estabelecimento' })
  associate(
    @Param('id') id: string,
    @Param('establishmentId') establishmentId: string,
  ) {
    return this.vetService.associate(id, establishmentId);
  }

  @Patch(':id/dissociate')
  @ApiOperation({ summary: 'Desassociar veterinário do estabelecimento' })
  dissociate(@Param('id') id: string) {
    return this.vetService.dissociate(id);
  }

  @Patch(':id/deactivate')
  @HttpCode(200)
  @ApiOperation({ summary: 'Desativar veterinário' })
  deactivate(@Param('id') id: string) {
    return this.vetService.deactivate(id);
  }

  @Patch(':id/activate')
  @HttpCode(200)
  @ApiOperation({ summary: 'Reativar veterinário' })
  activate(@Param('id') id: string) {
    return this.vetService.activate(id);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.vetService.remove(id);
  }
}
