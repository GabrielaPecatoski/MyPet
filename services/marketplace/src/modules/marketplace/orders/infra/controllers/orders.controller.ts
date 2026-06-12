import { OrderService } from "@market/orders/application/services/order.service";
import type { OrderStatus } from "@market/orders/domain/models/order.entity";
import { Body, Controller, Get, Param, Patch, Post } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";

@ApiTags("marketplace/orders")
@ApiBearerAuth()
@Controller("marketplace/orders")
export class OrdersController {
  constructor(private readonly orderService: OrderService) {}

  @Post(":userId")
  @RequirePermissions(Permission.ORDERS_WRITE)
  @ApiOperation({ summary: "Finalizar compra (checkout)" })
  async checkout(@Param("userId") userId: string) {
    return this.orderService.checkout(userId);
  }

  @Get("establishment/:establishmentId")
  @RequirePermissions(Permission.ORDERS_READ)
  @ApiOperation({ summary: "Listar pedidos de um estabelecimento" })
  async findByEstablishment(@Param("establishmentId") establishmentId: string) {
    return this.orderService.findByEstablishmentId(establishmentId);
  }

  @Get(":userId")
  @RequirePermissions(Permission.ORDERS_READ)
  @ApiOperation({ summary: "Listar pedidos do usuário" })
  async findByUser(@Param("userId") userId: string) {
    return this.orderService.findByUserId(userId);
  }

  @Patch(":id/status")
  @RequirePermissions(Permission.ORDERS_WRITE)
  @ApiOperation({ summary: "Atualizar status do pedido (acompanhamento)" })
  async updateStatus(
    @Param("id") id: string,
    @Body() body: { status: OrderStatus },
  ) {
    return this.orderService.updateStatus(id, body.status);
  }

  @Patch(":id/advance")
  @RequirePermissions(Permission.ORDERS_WRITE)
  @ApiOperation({ summary: "Avançar o pedido para o próximo status" })
  async advance(@Param("id") id: string) {
    return this.orderService.advanceStatus(id);
  }
}
