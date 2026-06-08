import { OrderDto } from "@market/orders/application/dto/order.dto";
import { Order } from "@market/orders/domain/models/order.entity";
import {
  ORDER_REPOSITORY,
  type OrderRepository,
} from "@market/orders/domain/repositories/order-repository.interface";
import { CART_REPOSITORY, type CartRepository } from "@market/cart/domain/repositories/cart-repository.interface";
import { PRODUCT_REPOSITORY, type ProductRepository } from "@market/products/domain/repositories/product-repository.interface";
import { BadRequestException, Inject, Injectable, Logger, NotFoundException } from "@nestjs/common";
import { SharedMessagingService } from "@shared/infra/messaging/shared-messaging.service";
import { MarketplaceExchangeName, MarketplaceRoutingKey } from "@shared/contracts/events/marketplace-events.enum";

@Injectable()
export class OrderService {
  private readonly logger = new Logger(OrderService.name);

  constructor(
    @Inject(ORDER_REPOSITORY) private readonly orderRepo: OrderRepository,
    @Inject(CART_REPOSITORY) private readonly cartRepo: CartRepository,
    @Inject(PRODUCT_REPOSITORY) private readonly productRepo: ProductRepository,
    private readonly messaging: SharedMessagingService,
  ) {}

  async checkout(userId: string): Promise<OrderDto> {
    const cartItems = await this.cartRepo.findByUserId(userId);
    if (cartItems.length === 0) throw new BadRequestException("Carrinho vazio");

    let total = 0;
    const orderItems = [];

    for (const item of cartItems) {
      const product = await this.productRepo.findById(item.productId);
      if (!product) continue;
      const price = product.price * item.quantity;
      total += price;
      orderItems.push({ productId: item.productId, quantity: item.quantity, price: product.price });
    }

    const order = Order.restore({
      userId,
      total,
      status: "AGUARDANDO_PAGAMENTO",
      items: orderItems,
    })!;

    await this.orderRepo.create(order);
    await this.cartRepo.clearCart(userId);

    const created = (await this.orderRepo.findByUserId(userId)).pop();
    return OrderDto.fromOrder(created!)!;
  }

  async processPayment(orderId: string, method: string, cardNumber?: string, installments?: number): Promise<{ order: OrderDto; payment: Record<string, unknown> }> {
    const order = await this.orderRepo.findById(orderId);
    if (!order) throw new NotFoundException("Pedido não encontrado");

    const payment = this.simulatePayment(method, order.total, cardNumber, installments);

    if (payment["status"] === "APPROVED") {
      await this.orderRepo.updateStatus(orderId, "CONFIRMED");
      await this.safePublish(MarketplaceExchangeName.ORDER_CREATED, MarketplaceRoutingKey.ORDER_CREATED, {
        orderId,
        userId: order.userId,
        total: order.total,
        itemCount: order.items.length,
      });
    }

    const updated = await this.orderRepo.findById(orderId);
    return { order: OrderDto.fromOrder(updated!)!, payment };
  }

  async findByUserId(userId: string): Promise<OrderDto[]> {
    const orders = await this.orderRepo.findByUserId(userId);
    return orders.map((o) => OrderDto.fromOrder(o)!);
  }

  private simulatePayment(method: string, amount: number, cardNumber?: string, installments?: number): Record<string, unknown> {
    const base = { method, amount };

    if (method === "PIX") {
      return { ...base, status: "APPROVED", pixKey: "mypet@pagamentos.com" };
    }
    if (method === "BOLETO") {
      const code = "34191.75501 34191.75501 34191.75501 1 " + String(Math.floor(amount * 100)).padStart(14, "0");
      return { ...base, status: "APPROVED", boletoCode: code };
    }
    if (method === "CREDIT_CARD" || method === "DEBIT_CARD") {
      const lastFour = cardNumber ? cardNumber.slice(-4) : "0000";
      const rejected = method === "CREDIT_CARD" && Math.random() < 0.05;
      if (rejected) return { ...base, status: "REJECTED", rejectionReason: "Cartão recusado pela operadora." };
      return { ...base, status: "APPROVED", cardLastFour: lastFour, installments: installments ?? 1 };
    }
    return { ...base, status: "APPROVED" };
  }

  private async safePublish(exchange: string, routingKey: string, payload: unknown): Promise<void> {
    try {
      await this.messaging.assertExchange(exchange, "direct");
      await this.messaging.publish(exchange, routingKey, payload);
    } catch (err) {
      this.logger.warn(`RabbitMQ publish failed [${routingKey}]: ${err}`);
    }
  }
}
