// @ts-ignore
import { Controller, Post, Get, Put, Param, Body, Query, HttpCode, HttpStatus } from '@nestjs/common';
// @ts-ignore
import { PetsService } from './pets.service';
// @ts-ignore
import { CreatePetDto, UpdatePetDto } from './pet.dto';

@Controller('pets')
export class PetsController {
  constructor(private readonly petsService: PetsService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createPetDto: CreatePetDto) {
    return await this.petsService.create(createPetDto);
  }

  @Get('user/:userId')
  @HttpCode(HttpStatus.OK)
  async findByUserId(
    @Param('userId') userId: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    const parsedSkip = Number(skip) || 0;
    const parsedTake = Number(take) || 10;
    return await this.petsService.findByUserId(userId, parsedSkip, parsedTake);
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async findById(@Param('id') petId: string) {
    return await this.petsService.findById(petId);
  }

  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(@Param('id') petId: string, @Body() updatePetDto: UpdatePetDto) {
    return await this.petsService.update(petId, updatePetDto);
  }
}
