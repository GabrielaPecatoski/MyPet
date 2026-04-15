import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
} from '@nestjs/common';
import { EstablishmentService } from './establishment.service';
import { CreateEstablishmentDto } from './dto/create-establishment.dto';
import { UpdateEstablishmentDto } from './dto/update-establishment.dto';
import { CreateServiceDto } from './dto/create-service.dto';

@Controller('establishments')
export class EstablishmentController {
  constructor(private readonly establishmentService: EstablishmentService) {}

  @Get()
  findAll(@Query('search') search?: string) {
    return this.establishmentService.findAll(search);
  }

  @Get('owner/:ownerId')
  findByOwner(@Param('ownerId') ownerId: string) {
    return this.establishmentService.findByOwner(ownerId);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.establishmentService.findById(id);
  }

  @Post('owner/:ownerId')
  create(
    @Param('ownerId') ownerId: string,
    @Body() dto: CreateEstablishmentDto,
  ) {
    return this.establishmentService.create(ownerId, dto);
  }

  @Patch(':id')
  update(@Param('id') id: string, @Body() dto: UpdateEstablishmentDto) {
    return this.establishmentService.update(id, dto);
  }

  @Post(':id/services')
  addService(@Param('id') id: string, @Body() dto: CreateServiceDto) {
    return this.establishmentService.addService(id, dto);
  }

  @Delete(':id/services/:serviceId')
  @HttpCode(204)
  removeService(
    @Param('id') id: string,
    @Param('serviceId') serviceId: string,
  ) {
    return this.establishmentService.removeService(id, serviceId);
  }
}
