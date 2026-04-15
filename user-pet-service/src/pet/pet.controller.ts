import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  HttpCode,
  UsePipes,
  ValidationPipe,
} from '@nestjs/common';
import { PetService } from './pet.service';
import { CreatePetDto } from './dto/create-pet.dto';
import { UpdatePetDto } from './dto/update-pet.dto';

@Controller('pets')
export class PetController {
  constructor(private readonly petService: PetService) {}

  @Get('user/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.petService.findByUser(userId);
  }

  @Get(':id')
  findById(@Param('id') id: string) {
    return this.petService.findById(id);
  }

  @Post('user/:userId')
  @HttpCode(201)
  @UsePipes(new ValidationPipe({ whitelist: true }))
  create(@Param('userId') userId: string, @Body() dto: CreatePetDto) {
    return this.petService.create(userId, dto);
  }

  @Patch(':id')
  @UsePipes(new ValidationPipe({ whitelist: true }))
  update(@Param('id') id: string, @Body() dto: UpdatePetDto) {
    return this.petService.update(id, dto);
  }

  @Delete(':id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.petService.remove(id);
  }
}
