// @ts-ignore
import { Injectable } from '@nestjs/common';
// @ts-ignore
import { Booking, BookingStatus, ServiceType } from './booking.entity';
// @ts-ignore
import { CreateBookingDto, UpdateBookingDto, UpdateBookingStatusDto, BookingFilterDto } from './booking.dto';

@Injectable()
export class BookingsService {
  private bookings: Booking[] = [];

  /**
   * Validates time in HH:MM format
   * @param time Time string to validate
   * @returns true if valid
   */
  private validateTime(time: string): boolean {
    const timeRegex = /^([0-1][0-9]|2[0-3]):([0-5][0-9])$/;
    return timeRegex.test(time);
  }

  /**
   * Validates service type
   * @param serviceType Service type to validate
   * @returns true if valid
   */
  private validateServiceType(serviceType: string): boolean {
    return Object.values(ServiceType).includes(serviceType as ServiceType);
  }

  /**
   * Validates booking date (must be future date)
   * @param date Booking date
   * @returns true if valid
   */
  private validateFutureDate(date: Date): boolean {
    const bookingDate = new Date(date);
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    return bookingDate >= today;
  }

  /**
   * Validates duration
   * @param duration Duration in minutes
   * @returns true if valid
   */
  private validateDuration(duration: number): boolean {
    return duration > 0 && duration <= 480; // max 8 hours
  }

  /**
   * Creates a new booking
   * @param createBookingDto Booking creation DTO
   * @returns Created booking
   * @throws Error if validation fails
   */
  async create(createBookingDto: CreateBookingDto): Promise<Booking> {
    if (!createBookingDto.userId || !createBookingDto.userId.trim()) {
      throw new Error('UserId is required');
    }

    if (!createBookingDto.petId || !createBookingDto.petId.trim()) {
      throw new Error('PetId is required');
    }

    if (!createBookingDto.establishmentId || !createBookingDto.establishmentId.trim()) {
      throw new Error('EstablishmentId is required');
    }

    if (!this.validateServiceType(createBookingDto.serviceType)) {
      throw new Error('Invalid service type');
    }

    if (!this.validateTime(createBookingDto.scheduledTime)) {
      throw new Error('Invalid time format. Use HH:MM (24-hour format)');
    }

    if (!this.validateFutureDate(createBookingDto.scheduledDate)) {
      throw new Error('Scheduled date must be in the future');
    }

    if (!this.validateDuration(createBookingDto.duration)) {
      throw new Error('Duration must be between 1 and 480 minutes');
    }

    // Check for scheduling conflicts
    const hasConflict = this.bookings.some((b) => {
      const sameDateAndEstablishment =
        b.establishmentId === createBookingDto.establishmentId &&
        new Date(b.scheduledDate).toDateString() ===
          new Date(createBookingDto.scheduledDate).toDateString() &&
        [BookingStatus.CONFIRMED, BookingStatus.IN_PROGRESS].includes(b.status);

      if (!sameDateAndEstablishment) return false;

      const [bookingHour, bookingMin] = b.scheduledTime.split(':').map(Number);
      const [newHour, newMin] = createBookingDto.scheduledTime.split(':').map(Number);

      const bookingStart = bookingHour * 60 + bookingMin;
      const bookingEnd = bookingStart + b.duration;
      const newStart = newHour * 60 + newMin;
      const newEnd = newStart + createBookingDto.duration;

      // Check for overlap
      return newStart < bookingEnd && newEnd > bookingStart;
    });

    if (hasConflict) {
      throw new Error('Time slot is not available for this establishment');
    }

    const booking = new Booking(
      createBookingDto.userId,
      createBookingDto.petId,
      createBookingDto.establishmentId,
      createBookingDto.serviceType,
      new Date(createBookingDto.scheduledDate),
      createBookingDto.scheduledTime,
      createBookingDto.duration,
    );

    if (createBookingDto.notes) booking.notes = createBookingDto.notes.trim();
    if (createBookingDto.totalPrice !== undefined) booking.totalPrice = createBookingDto.totalPrice;

    this.bookings.push(booking);
    return booking;
  }

  /**
   * Finds all bookings with filtering
   * @param filter Filter criteria
   * @param skip Pagination skip
   * @param take Pagination take
   * @returns Array of bookings
   */
  async findAll(filter: BookingFilterDto = {}, skip: number = 0, take: number = 10): Promise<Booking[]> {
    skip = Math.max(0, skip || 0);
    take = Math.min(100, Math.max(1, take || 10));

    let filtered = [...this.bookings];

    if (filter.userId) {
      filtered = filtered.filter((b) => b.userId === filter.userId);
    }

    if (filter.establishmentId) {
      filtered = filtered.filter((b) => b.establishmentId === filter.establishmentId);
    }

    if (filter.petId) {
      filtered = filtered.filter((b) => b.petId === filter.petId);
    }

    if (filter.status) {
      filtered = filtered.filter((b) => b.status === filter.status);
    }

    if (filter.dateFrom) {
      const dateFrom = new Date(filter.dateFrom);
      dateFrom.setHours(0, 0, 0, 0);
      filtered = filtered.filter((b) => b.scheduledDate >= dateFrom);
    }

    if (filter.dateTo) {
      const dateTo = new Date(filter.dateTo);
      dateTo.setHours(23, 59, 59, 999);
      filtered = filtered.filter((b) => b.scheduledDate <= dateTo);
    }

    // Sort by scheduled date
    filtered.sort((a, b) => new Date(b.scheduledDate).getTime() - new Date(a.scheduledDate).getTime());

    return filtered.slice(skip, skip + take);
  }

  /**
   * Gets a specific booking by ID
   * @param bookingId Booking ID
   * @returns Booking or null
   */
  async findById(bookingId: string): Promise<Booking | null> {
    if (!bookingId || !bookingId.trim()) {
      throw new Error('BookingId is required');
    }

    return this.bookings.find((b) => b.id === bookingId) || null;
  }

  /**
   * Gets booking status details
   * @param bookingId Booking ID
   * @returns Booking status information
   */
  async getBookingStatus(bookingId: string): Promise<{
    id: string;
    status: BookingStatus;
    scheduledDate: Date;
    scheduledTime: string;
    duration: number;
    serviceType: ServiceType;
    notes?: string;
    feedback?: string;
    rating?: number;
  }> {
    const booking = await this.findById(bookingId);

    if (!booking) {
      throw new Error('Booking not found');
    }

    return {
      id: booking.id,
      status: booking.status,
      scheduledDate: booking.scheduledDate,
      scheduledTime: booking.scheduledTime,
      duration: booking.duration,
      serviceType: booking.serviceType,
      notes: booking.notes,
      feedback: booking.feedback,
      rating: booking.rating,
    };
  }

  /**
   * Gets all bookings for a user's agenda
   * @param userId User ID
   * @param skip Pagination skip
   * @param take Pagination take
   * @returns Array of user bookings sorted by date
   */
  async getUserAgenda(userId: string, skip: number = 0, take: number = 10): Promise<Booking[]> {
    if (!userId || !userId.trim()) {
      throw new Error('UserId is required');
    }

    return this.findAll({ userId }, skip, take);
  }

  /**
   * Gets establishment's agenda
   * @param establishmentId Establishment ID
   * @param skip Pagination skip
   * @param take Pagination take
   * @returns Array of establishment bookings sorted by date
   */
  async getEstablishmentAgenda(establishmentId: string, skip: number = 0, take: number = 10): Promise<Booking[]> {
    if (!establishmentId || !establishmentId.trim()) {
      throw new Error('EstablishmentId is required');
    }

    return this.findAll(
      {
        establishmentId,
        status: BookingStatus.CONFIRMED,
      },
      skip,
      take,
    );
  }

  /**
   * Updates booking information
   * @param bookingId Booking ID
   * @param updateBookingDto Update DTO
   * @returns Updated booking
   * @throws Error if booking not found
   */
  async update(bookingId: string, updateBookingDto: UpdateBookingDto): Promise<Booking> {
    const booking = await this.findById(bookingId);

    if (!booking) {
      throw new Error('Booking not found');
    }

    if ([BookingStatus.COMPLETED, BookingStatus.CANCELLED].includes(booking.status)) {
      throw new Error(`Cannot update a ${booking.status.toLowerCase()} booking`);
    }

    if (updateBookingDto.notes !== undefined) {
      booking.notes = updateBookingDto.notes.trim();
    }

    if (updateBookingDto.totalPrice !== undefined) {
      booking.totalPrice = updateBookingDto.totalPrice;
    }

    if (updateBookingDto.feedback !== undefined) {
      if (booking.status !== BookingStatus.COMPLETED) {
        throw new Error('Feedback can only be added to completed bookings');
      }
      booking.feedback = updateBookingDto.feedback.trim();
    }

    if (updateBookingDto.rating !== undefined) {
      if (booking.status !== BookingStatus.COMPLETED) {
        throw new Error('Rating can only be added to completed bookings');
      }
      if (updateBookingDto.rating < 0 || updateBookingDto.rating > 5) {
        throw new Error('Rating must be between 0 and 5');
      }
      booking.rating = updateBookingDto.rating;
    }

    booking.updatedAt = new Date();
    return booking;
  }

  /**
   * Updates booking status (with workflow validation)
   * @param bookingId Booking ID
   * @param updateStatusDto Status update DTO
   * @returns Updated booking
   * @throws Error if invalid status transition
   */
  async updateStatus(bookingId: string, updateStatusDto: UpdateBookingStatusDto): Promise<Booking> {
    const booking = await this.findById(bookingId);

    if (!booking) {
      throw new Error('Booking not found');
    }

    const currentStatus = booking.status;
    const newStatus = updateStatusDto.status;

    // Validate status transitions
    const validTransitions: Record<BookingStatus, BookingStatus[]> = {
      [BookingStatus.PENDING]: [BookingStatus.CONFIRMED, BookingStatus.CANCELLED],
      [BookingStatus.CONFIRMED]: [BookingStatus.IN_PROGRESS, BookingStatus.CANCELLED],
      [BookingStatus.IN_PROGRESS]: [BookingStatus.COMPLETED, BookingStatus.CANCELLED],
      [BookingStatus.COMPLETED]: [],
      [BookingStatus.CANCELLED]: [],
    };

    if (!validTransitions[currentStatus].includes(newStatus)) {
      throw new Error(`Cannot transition from ${currentStatus} to ${newStatus}`);
    }

    booking.status = newStatus;

    if (newStatus === BookingStatus.CANCELLED && updateStatusDto.cancellationReason) {
      booking.cancellationReason = updateStatusDto.cancellationReason.trim();
    }

    booking.updatedAt = new Date();
    return booking;
  }

  /**
   * Gets booking statistics
   * @param userId User ID (optional - if provided, stats for user; otherwise global)
   * @returns Booking statistics
   */
  async getStats(userId?: string): Promise<{
    total: number;
    pending: number;
    confirmed: number;
    inProgress: number;
    completed: number;
    cancelled: number;
  }> {
    let filtered = this.bookings;

    if (userId) {
      filtered = filtered.filter((b) => b.userId === userId);
    }

    return {
      total: filtered.length,
      pending: filtered.filter((b) => b.status === BookingStatus.PENDING).length,
      confirmed: filtered.filter((b) => b.status === BookingStatus.CONFIRMED).length,
      inProgress: filtered.filter((b) => b.status === BookingStatus.IN_PROGRESS).length,
      completed: filtered.filter((b) => b.status === BookingStatus.COMPLETED).length,
      cancelled: filtered.filter((b) => b.status === BookingStatus.CANCELLED).length,
    };
  }
}
