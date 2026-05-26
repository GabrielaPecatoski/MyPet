import { OrderService } from "@market/orders/application/services/order.service";
import { Controller, Get, HttpCode, HttpStatus, Param, Post } from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
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

  @Get(":userId")
  @RequirePermissions(Permission.ORDERS_READ)
  @ApiOperation({ summary: "Listar pedidos do usuário" })
  async findByUser(@Param("userId") userId: string) {
    return this.orderService.findByUserId(userId);
  }
}
