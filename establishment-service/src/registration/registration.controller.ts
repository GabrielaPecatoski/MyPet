// @ts-ignore
import { Controller, Post, Get, Put, Delete, Body, Param, HttpCode, HttpStatus, Query } from '@nestjs/common';
// @ts-ignore
import { RegistrationService } from './registration.service';
// @ts-ignore
import { CreateRegistrationDto } from './dto/create-registration.dto';
// @ts-ignore
import { UpdateRegistrationDto } from './dto/update-registration.dto';
// @ts-ignore
import { RegistrationStatus } from './entities/registration.entity';

@Controller('establishments')
export class RegistrationController {
  constructor(private readonly registrationService: RegistrationService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createRegistrationDto: CreateRegistrationDto) {
    return this.registrationService.create(createRegistrationDto);
  }

  @Get('registrations/stats')
  @HttpCode(HttpStatus.OK)
  async getStats() {
    return this.registrationService.getStats();
  }

  @Get('registrations')
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query('status') status?: RegistrationStatus,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    if (status) {
      return this.registrationService.findByStatus(status, skip, take);
    }
    return this.registrationService.findAll(skip, take);
  }

  @Get('registrations/:id')
  @HttpCode(HttpStatus.OK)
  async findOne(@Param('id') id: string) {
    return this.registrationService.findOne(id);
  }

  @Put('registrations/:id')
  @HttpCode(HttpStatus.OK)
  async update(
    @Param('id') id: string,
    @Body() updateRegistrationDto: UpdateRegistrationDto,
  ) {
    return this.registrationService.update(id, updateRegistrationDto);
  }

  @Put('registrations/:id/status')
  @HttpCode(HttpStatus.OK)
  async updateStatus(
    @Param('id') id: string,
    @Body() { status }: { status: RegistrationStatus },
  ) {
    return this.registrationService.updateStatus(id, status);
  }

  @Delete('registrations/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  async remove(@Param('id') id: string) {
    return this.registrationService.remove(id);
  }
}
