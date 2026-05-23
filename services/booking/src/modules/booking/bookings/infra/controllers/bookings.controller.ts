import { CreateBookingDto } from "@booking/bookings/application/dto/create-booking.dto";
import { BookingDto } from "@booking/bookings/application/dto/booking.dto";
import { BookingService } from "@booking/bookings/application/services/booking.service";
import type { BookingStatus } from "@booking/bookings/domain/models/booking.entity";
import { AvailabilityService } from "@booking/availability/application/services/availability.service";
import {
  Body,
  Controller,
  Delete,
  Get,
  HttpCode,
  HttpStatus,
  Param,
  Patch,
  Post,
  Query,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";
import { HateoasItem } from "@shared/infra/hateoas";
import { Public } from "@shared/infra/decorators/public.decorator";

@ApiTags("bookings")
@ApiBearerAuth()
@Controller("bookings")
export class BookingsController {
  constructor(private readonly bookingService: BookingService) {}

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @RequirePermissions(Permission.BOOKINGS_WRITE)
  @ApiOperation({ summary: "Criar agendamento" })
  async create(
    @CurrentUser() user: AuthenticatedUser,
    @Body() body: CreateBookingDto,
  ): Promise<BookingDto> {
    return this.bookingService.create(user.sub, user.email, body);
  }

  @Get("user/:userId")
  @RequirePermissions(Permission.BOOKINGS_READ)
  @ApiOperation({ summary: "Listar agendamentos do usuário" })
  async findByUser(@Param("userId") userId: string): Promise<BookingDto[]> {
    return this.bookingService.findByUser(userId);
  }

  @Get("establishment/:establishmentId")
  @RequirePermissions(Permission.BOOKINGS_READ)
  @ApiOperation({ summary: "Listar agendamentos do estabelecimento" })
  async findByEstablishment(@Param("establishmentId") id: string): Promise<BookingDto[]> {
    return this.bookingService.findByEstablishment(id);
  }

  @Get("establishment/:establishmentId/stats")
  @RequirePermissions(Permission.BOOKINGS_READ)
  @ApiOperation({ summary: "Estatísticas de agendamentos do estabelecimento" })
  async getStats(@Param("establishmentId") id: string) {
    return this.bookingService.getStats(id);
  }

  @Get(":id")
  @RequirePermissions(Permission.BOOKINGS_READ)
  @ApiOperation({ summary: "Buscar agendamento por ID" })
  @HateoasItem<BookingDto>({
    basePath: "/v1/bookings",
    itemLinks: (item) => ({
      self: { href: `/v1/bookings/${item.id}`, method: "GET" },
      cancel: { href: `/v1/bookings/${item.id}/cancel`, method: "PATCH" },
      complete: { href: `/v1/bookings/${item.id}/complete`, method: "PATCH" },
    }),
  })
  async findById(@Param("id") id: string) {
    return this.bookingService.findById(id);
  }

  @Patch(":id/status")
  @RequirePermissions(Permission.BOOKINGS_WRITE)
  @ApiOperation({ summary: "Atualizar status do agendamento" })
  async updateStatus(
    @Param("id") id: string,
    @Body() body: { status: BookingStatus },
  ): Promise<BookingDto> {
    return this.bookingService.updateStatus(id, body.status);
  }

  @Patch(":id/cancel")
  @RequirePermissions(Permission.BOOKINGS_WRITE)
  @ApiOperation({ summary: "Cancelar agendamento" })
  async cancel(@Param("id") id: string): Promise<BookingDto> {
    return this.bookingService.cancel(id);
  }

  @Patch(":id/complete")
  @RequirePermissions(Permission.BOOKINGS_WRITE)
  @ApiOperation({ summary: "Concluir agendamento" })
  async complete(@Param("id") id: string): Promise<BookingDto> {
    return this.bookingService.complete(id);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.BOOKINGS_DELETE)
  @ApiOperation({ summary: "Remover agendamento" })
  @ApiNoContentResponse({ description: "Agendamento removido" })
  async remove(@Param("id") id: string) {
    return this.bookingService.remove(id);
  }
}

@ApiTags("availability")
@ApiBearerAuth()
@Controller("availability")
export class AvailabilityController {
  constructor(private readonly availabilityService: AvailabilityService) {}

  @Get("schedule/:estabId")
  @RequirePermissions(Permission.AVAILABILITY_READ)
  @ApiOperation({ summary: "Buscar horários do estabelecimento" })
  async getSchedule(@Param("estabId") estabId: string) {
    return this.availabilityService.getFullSchedule(estabId);
  }

  @Post("schedule")
  @RequirePermissions(Permission.AVAILABILITY_WRITE)
  @ApiOperation({ summary: "Definir horário completo do estabelecimento" })
  async setSchedule(@Body() body: {
    establishmentId: string;
    slotDurationMinutes: number;
    capacity?: number;
    days: { dayOfWeek: number; startTime: string; endTime: string; isOpen: boolean }[];
  }) {
    return this.availabilityService.setFullSchedule(body);
  }

  @Get("blocked/:estabId")
  @RequirePermissions(Permission.AVAILABILITY_READ)
  @ApiOperation({ summary: "Listar horários bloqueados" })
  async getBlocked(@Param("estabId") estabId: string) {
    return this.availabilityService.getBlockedSlots(estabId);
  }

  @Post("block")
  @RequirePermissions(Permission.AVAILABILITY_WRITE)
  @ApiOperation({ summary: "Bloquear horário" })
  async blockSlot(@Body() body: { establishmentId: string; date: string; startTime: string; endTime: string; reason?: string }) {
    return this.availabilityService.blockSlot(body);
  }

  @Delete("block/:id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.AVAILABILITY_WRITE)
  @ApiOperation({ summary: "Desbloquear horário" })
  @ApiNoContentResponse({ description: "Horário desbloqueado" })
  async unblockSlot(@Param("id") id: string) {
    return this.availabilityService.unblockSlot(id);
  }

  @Get(":estabId")
  @Public()
  @ApiOperation({ summary: "Listar slots disponíveis para uma data" })
  async getAvailability(
    @Param("estabId") estabId: string,
    @Query("date") date: string,
  ) {
    return this.availabilityService.getAvailableSlots(estabId, date);
  }
}
