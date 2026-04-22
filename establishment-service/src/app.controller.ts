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
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  @Get('establishments')
  findAll(@Query('search') search?: string) {
    return this.appService.findAll(search);
  }

  @Get('establishments/owner/:ownerId')
  findByOwner(@Param('ownerId') ownerId: string) {
    return this.appService.findByOwner(ownerId);
  }

  @Get('establishments/:id')
  findById(@Param('id') id: string) {
    return this.appService.findById(id);
  }

  @Post('establishments/owner/:ownerId')
  create(
    @Param('ownerId') ownerId: string,
    @Body()
    body: {
      name?: string;
      description?: string;
      address?: string;
      city?: string;
      phone?: string;
      type?: string;
      imageUrl?: string | null;
    },
  ) {
    return this.appService.create(ownerId, body);
  }

  @Patch('establishments/:id')
  update(
    @Param('id') id: string,
    @Body()
    body: {
      name?: string;
      description?: string;
      address?: string;
      city?: string;
      phone?: string;
      type?: string;
      imageUrl?: string | null;
      rating?: number;
      reviewCount?: number;
    },
  ) {
    return this.appService.update(id, body);
  }

  @Post('establishments/:id/services')
  addService(
    @Param('id') id: string,
    @Body()
    body: {
      name: string;
      price: number;
      durationMinutes: number;
      description?: string;
    },
  ) {
    return this.appService.addService(id, body);
  }

  @Delete('establishments/:id/services/:serviceId')
  @HttpCode(200)
  removeService(
    @Param('id') id: string,
    @Param('serviceId') serviceId: string,
  ) {
    return this.appService.removeService(id, serviceId);
  }
}
