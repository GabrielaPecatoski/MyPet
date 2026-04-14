// @ts-ignore
import { Controller, Post, Get, Put, Body, Param, HttpCode, HttpStatus, Query } from '@nestjs/common';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateProfileDto } from './dto/update-profile.dto';

@Controller('users')
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Post('register')
  @HttpCode(HttpStatus.CREATED)
  async register(@Body() createUserDto: CreateUserDto) {
    return this.usersService.create(createUserDto);
  }

  @Get('stats/overview')
  @HttpCode(HttpStatus.OK)
  async getUserStats() {
    return this.usersService.getUserStats();
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async listUsers(@Query('skip') skip?: number, @Query('take') take?: number) {
    return this.usersService.listUsers(skip, take);
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async getProfile(@Param('id') userId: string) {
    return this.usersService.getProfile(userId);
  }

  @Put(':id/profile')
  @HttpCode(HttpStatus.OK)
  async updateProfile(
    @Param('id') userId: string,
    @Body() updateProfileDto: UpdateProfileDto,
  ) {
    return this.usersService.updateProfile(userId, updateProfileDto);
  }
}
