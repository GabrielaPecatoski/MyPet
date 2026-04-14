// @ts-ignore
import { Controller, Post, Get, Put, Body, Param, HttpCode, HttpStatus, Query } from '@nestjs/common';
// @ts-ignore
import { BookingsService } from './bookings.service';
// @ts-ignore
import { CreateBookingDto, UpdateBookingDto, UpdateBookingStatusDto } from './booking.dto';
// @ts-ignore
import { BookingStatus } from './booking.entity';

@Controller('bookings')
export class BookingsController {
  constructor(private readonly bookingsService: BookingsService) {}

  /**
   * Creates a new booking/appointment
   * @returns Created booking with 201 status
   */
  @Post()
  @HttpCode(HttpStatus.CREATED)
  async create(@Body() createBookingDto: CreateBookingDto) {
    try {
      return await this.bookingsService.create(createBookingDto);
    } catch (error) {
      throw new Error(`Failed to create booking: ${error.message}`);
    }
  }

  /**
   * Lists all bookings with optional filters
   * @returns Array of bookings
   */
  @Get()
  @HttpCode(HttpStatus.OK)
  async findAll(
    @Query('userId') userId?: string,
    @Query('establishmentId') establishmentId?: string,
    @Query('petId') petId?: string,
    @Query('status') status?: BookingStatus,
    @Query('dateFrom') dateFrom?: string,
    @Query('dateTo') dateTo?: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    try {
      const filter: any = {};
      if (userId) filter.userId = userId;
      if (establishmentId) filter.establishmentId = establishmentId;
      if (petId) filter.petId = petId;
      if (status) filter.status = status;
      if (dateFrom) filter.dateFrom = new Date(dateFrom);
      if (dateTo) filter.dateTo = new Date(dateTo);

      return await this.bookingsService.findAll(filter, skip, take);
    } catch (error) {
      throw new Error(`Failed to fetch bookings: ${error.message}`);
    }
  }

  /**
   * Gets a specific booking by ID
   * @returns Booking information
   */
  @Get('detail/:id')
  @HttpCode(HttpStatus.OK)
  async findById(@Param('id') bookingId: string) {
    try {
      const booking = await this.bookingsService.findById(bookingId);
      if (!booking) {
        throw new Error('Booking not found');
      }
      return booking;
    } catch (error) {
      throw new Error(`Failed to fetch booking: ${error.message}`);
    }
  }

  /**
   * Gets booking status and tracking information
   * @returns Booking status details
   */
  @Get(':id/status')
  @HttpCode(HttpStatus.OK)
  async getBookingStatus(@Param('id') bookingId: string) {
    try {
      return await this.bookingsService.getBookingStatus(bookingId);
    } catch (error) {
      throw new Error(`Failed to fetch booking status: ${error.message}`);
    }
  }

  /**
   * Gets user's booking agenda/schedule
   * @returns Array of user bookings
   */
  @Get('user/:userId/agenda')
  @HttpCode(HttpStatus.OK)
  async getUserAgenda(
    @Param('userId') userId: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    try {
      return await this.bookingsService.getUserAgenda(userId, skip, take);
    } catch (error) {
      throw new Error(`Failed to fetch user agenda: ${error.message}`);
    }
  }

  /**
   * Gets establishment's booking agenda/schedule
   * @returns Array of establishment bookings
   */
  @Get('establishment/:establishmentId/agenda')
  @HttpCode(HttpStatus.OK)
  async getEstablishmentAgenda(
    @Param('establishmentId') establishmentId: string,
    @Query('skip') skip?: number,
    @Query('take') take?: number,
  ) {
    try {
      return await this.bookingsService.getEstablishmentAgenda(establishmentId, skip, take);
    } catch (error) {
      throw new Error(`Failed to fetch establishment agenda: ${error.message}`);
    }
  }

  /**
   * Updates booking information
   * @returns Updated booking
   */
  @Put(':id')
  @HttpCode(HttpStatus.OK)
  async update(@Param('id') bookingId: string, @Body() updateBookingDto: UpdateBookingDto) {
    try {
      return await this.bookingsService.update(bookingId, updateBookingDto);
    } catch (error) {
      throw new Error(`Failed to update booking: ${error.message}`);
    }
  }

  /**
   * Updates booking status (pending -> confirmed -> in progress -> completed)
   * @returns Updated booking
   */
  @Put(':id/status')
  @HttpCode(HttpStatus.OK)
  async updateStatus(@Param('id') bookingId: string, @Body() updateStatusDto: UpdateBookingStatusDto) {
    try {
      return await this.bookingsService.updateStatus(bookingId, updateStatusDto);
    } catch (error) {
      throw new Error(`Failed to update booking status: ${error.message}`);
    }
  }

  /**
   * Gets booking statistics
   * @returns Booking statistics
   */
  @Get('user/:userId/stats')
  @HttpCode(HttpStatus.OK)
  async getStats(@Param('userId') userId: string) {
    try {
      return await this.bookingsService.getStats(userId);
    } catch (error) {
      throw new Error(`Failed to fetch booking stats: ${error.message}`);
    }
  }
}
