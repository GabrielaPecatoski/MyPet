// @ts-ignore
import { Controller, Get, Put, Post, Body, Param, Query, HttpCode, HttpStatus } from '@nestjs/common';
import { EstablishmentProfileService } from './profile.service';
import { UpdateEstablishmentProfileDto } from './dto/update-establishment-profile.dto';
import { EstablishmentType } from './entities/establishment-profile.entity';

@Controller('establishments')
export class EstablishmentProfileController {
  constructor(private readonly profileService: EstablishmentProfileService) {}

  @Post('profile')
  @HttpCode(HttpStatus.CREATED)
  async createProfile(@Body() createProfileDto: any) {
    return this.profileService.createProfile(
      createProfileDto.ownerId,
      createProfileDto.cnpj,
      createProfileDto.name,
      createProfileDto.email,
      createProfileDto.phone,
      createProfileDto.address,
      createProfileDto.city,
      createProfileDto.state,
      createProfileDto.zipCode,
      createProfileDto.type || EstablishmentType.PET_SHOP,
      createProfileDto.services || [],
    );
  }

  @Get(':id')
  @HttpCode(HttpStatus.OK)
  async getProfile(@Param('id') establishmentId: string) {
    return this.profileService.getProfile(establishmentId);
  }

  @Get('owner/:ownerId')
  @HttpCode(HttpStatus.OK)
  async getProfileByOwnerId(@Param('ownerId') ownerId: string) {
    return this.profileService.getProfileByOwnerId(ownerId);
  }

  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async updateProfile(
    @Param('id') establishmentId: string,
    @Body() updateProfileDto: UpdateEstablishmentProfileDto,
  ) {
    return this.profileService.updateProfile(establishmentId, updateProfileDto);
  }

  @Get(':id/stats')
  @HttpCode(HttpStatus.OK)
  async getStats(@Param('id') establishmentId: string) {
    return this.profileService.getProfileStats(establishmentId);
  }

  @Get()
  @HttpCode(HttpStatus.OK)
  async listEstablishments(
    @Query('type') type?: EstablishmentType,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    return this.profileService.listEstablishments(type, skip, take);
  }

  @Get('search')
  @HttpCode(HttpStatus.OK)
  async search(
    @Query('q') query: string,
  ) {
    if (!query || query.length < 2) {
      return [];
    }
    return this.profileService.searchEstablishments(query);
  }

  @Get('search/query')
  @HttpCode(HttpStatus.OK)
  async searchByQuery(@Query('q') query: string) {
    if (!query || query.length < 2) {
      return [];
    }
    return this.profileService.searchEstablishments(query);
  }

  @Post(':id/follow')
  @HttpCode(HttpStatus.OK)
  async addFollower(@Param('id') establishmentId: string) {
    return this.profileService.addFollower(establishmentId);
  }

  @Put(':id/rating')
  @HttpCode(HttpStatus.OK)
  async updateRating(
    @Param('id') establishmentId: string,
    @Body() { rating }: { rating: number },
  ) {
    return this.profileService.updateRating(establishmentId, rating);
  }
}
