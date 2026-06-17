import { OrderService } from "@market/orders/application/services/order.service";
import { Body, Controller, Post } from "@nestjs/common";
import { ApiBearerAuth, ApiOperation, ApiTags } from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";

@ApiTags("marketplace/payments")
@ApiBearerAuth()
@Controller("marketplace/payments")
export class PaymentsController {
  constructor(private readonly orderService: OrderService) {}

  @Post()
  @RequirePermissions(Permission.ORDERS_WRITE)
  @ApiOperation({ summary: "Processar pagamento de pedido" })
  async processPayment(
    @Body() body: {
      orderId: string;
      method: string;
      cardNumber?: string;
      installments?: number;
      deliveryMethod?: string;
      deliveryAddress?: string;
    },
  ) {
    return this.orderService.processPayment(
      body.orderId,
      body.method,
      body.cardNumber,
      body.installments,
      body.deliveryMethod,
      body.deliveryAddress,
    );
  }
}
