import { CartService } from "@market/cart/application/services/cart.service";
import { CART_REPOSITORY } from "@market/cart/domain/repositories/cart-repository.interface";
import { CartController } from "@market/cart/infra/controllers/cart.controller";
import { DrizzleCartRepository } from "@market/cart/infra/repositories/drizzle-cart.repository";
import { OrderService } from "@market/orders/application/services/order.service";
import { ORDER_REPOSITORY } from "@market/orders/domain/repositories/order-repository.interface";
import { OrdersController } from "@market/orders/infra/controllers/orders.controller";
import { DrizzleOrderRepository } from "@market/orders/infra/repositories/drizzle-order.repository";
import { PaymentsController } from "@market/payments/infra/controllers/payments.controller";
import { ProductService } from "@market/products/application/services/product.service";
import { PRODUCT_REPOSITORY } from "@market/products/domain/repositories/product-repository.interface";
import { ProductsController } from "@market/products/infra/controllers/products.controller";
import { DrizzleProductRepository } from "@market/products/infra/repositories/drizzle-product.repository";
import { Module } from "@nestjs/common";

@Module({
  controllers: [
    ProductsController,
    CartController,
    OrdersController,
    PaymentsController,
  ],
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
