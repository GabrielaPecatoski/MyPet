import { Module } from "@nestjs/common";
import { ProductService } from "@market/products/application/services/product.service";
import { CartService } from "@market/cart/application/services/cart.service";
import { OrderService } from "@market/orders/application/services/order.service";
import { PRODUCT_REPOSITORY } from "@market/products/domain/repositories/product-repository.interface";
import { CART_REPOSITORY } from "@market/cart/domain/repositories/cart-repository.interface";
import { ORDER_REPOSITORY } from "@market/orders/domain/repositories/order-repository.interface";
import { DrizzleProductRepository } from "@market/products/infra/repositories/drizzle-product.repository";
import { DrizzleCartRepository } from "@market/cart/infra/repositories/drizzle-cart.repository";
import { DrizzleOrderRepository } from "@market/orders/infra/repositories/drizzle-order.repository";
import { ProductsController } from "@market/products/infra/controllers/products.controller";
import { CartController } from "@market/cart/infra/controllers/cart.controller";
import { OrdersController } from "@market/orders/infra/controllers/orders.controller";
import { PaymentsController } from "@market/payments/infra/controllers/payments.controller";

@Module({
  controllers: [ProductsController, CartController, OrdersController, PaymentsController],
  providers: [
    ProductService,
    CartService,
    OrderService,
    DrizzleProductRepository,
    DrizzleCartRepository,
    DrizzleOrderRepository,
    { provide: PRODUCT_REPOSITORY, useExisting: DrizzleProductRepository },
    { provide: CART_REPOSITORY, useExisting: DrizzleCartRepository },
    { provide: ORDER_REPOSITORY, useExisting: DrizzleOrderRepository },
  ],
})
export class MarketplaceModule {}
