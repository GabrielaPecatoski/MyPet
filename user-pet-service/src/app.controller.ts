import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  HttpCode,
} from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('pets/user/:userId')
  getPetsByUser(@Param('userId') userId: string) {
    return this.appService.findByUser(userId);
  }

  @Get('pets/:id')
  getPet(@Param('id') id: string) {
    return this.appService.findById(id);
  }

  @Post('pets/user/:userId')
  createPet(@Param('userId') userId: string, @Body() body: any) {
    return this.appService.create(userId, body);
  }

  @Patch('pets/:id')
  updatePet(@Param('id') id: string, @Body() body: any) {
    return this.appService.update(id, body);
  }

  @Delete('pets/:id')
  @HttpCode(204)
  deletePet(@Param('id') id: string) {
    return this.appService.remove(id);
  }
}
