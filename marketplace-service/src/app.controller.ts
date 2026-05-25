import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Body,
  Query,
  HttpCode,
} from '@nestjs/common';
import { AppService } from './app.service';
import { PaymentService, type CreatePaymentDto } from './payment.service';

@Controller()
export class AppController {
  constructor(
    private readonly appService: AppService,
    private readonly paymentService: PaymentService,
  ) {}

  @Get('marketplace/products')
  listProducts(
    @Query('search') search?: string,
    @Query('establishmentId') establishmentId?: string,
  ) {
    return this.appService.findAllProducts(search, establishmentId);
  }

  @Get('marketplace/products/:id')
  getProduct(@Param('id') id: string) {
    return this.appService.findProductById(id);
  }

  @Post('marketplace/products')
  createProduct(@Body() body: any) {
    return this.appService.createProduct(body);
  }

  @Patch('marketplace/products/:id')
  updateProduct(@Param('id') id: string, @Body() body: any) {
    return this.appService.updateProduct(id, body);
  }

  @Delete('marketplace/products/:id')
  @HttpCode(204)
  deleteProduct(@Param('id') id: string) {
    return this.appService.deleteProduct(id);
  }

  @Get('marketplace/cart/:userId')
  getCart(@Param('userId') userId: string) {
    return this.appService.getCart(userId);
  }

  @Post('marketplace/cart/:userId')
  addToCart(
    @Param('userId') userId: string,
    @Body() body: { productId: string; quantity: number },
  ) {
    return this.appService.addToCart(
      userId,
      body.productId,
      body.quantity ?? 1,
    );
  }

  @Patch('marketplace/cart/:userId/:productId')
  updateCartItem(
    @Param('userId') userId: string,
    @Param('productId') productId: string,
    @Body() body: { quantity: number },
  ) {
    return this.appService.updateCartItem(userId, productId, body.quantity);
  }

  @Delete('marketplace/cart/:userId/:productId')
  removeFromCart(
    @Param('userId') userId: string,
    @Param('productId') productId: string,
  ) {
    return this.appService.removeFromCart(userId, productId);
  }

  @Delete('marketplace/cart/:userId')
  @HttpCode(204)
  clearCart(@Param('userId') userId: string) {
    return this.appService.clearCart(userId);
  }

  @Get('marketplace/orders/establishment/:establishmentId')
  getOrdersByEstablishment(@Param('establishmentId') establishmentId: string) {
    return this.appService.getOrdersByEstablishment(establishmentId);
  }

  @Patch('marketplace/orders/:orderId/delivery')
  @HttpCode(200)
  updateDelivery(
    @Param('orderId') orderId: string,
    @Body() body: { deliveryStatus: string },
  ) {
    return this.appService.updateDeliveryStatus(orderId, body.deliveryStatus);
  }

  @Post('marketplace/orders/:userId')
  checkout(@Param('userId') userId: string) {
    return this.appService.checkout(userId);
  }

  @Get('marketplace/orders/:userId')
  getUserOrders(@Param('userId') userId: string) {
    return this.appService.getUserOrders(userId);
  }

  @Post('marketplace/payments')
  createPayment(@Body() body: CreatePaymentDto) {
    return this.paymentService.processPayment(body);
  }

  @Get('marketplace/payments/user/:userId')
  getPaymentsByUser(@Param('userId') userId: string) {
    return this.paymentService.findByUser(userId);
  }

  @Get('marketplace/payments/order/:orderId')
  getPaymentsByOrder(@Param('orderId') orderId: string) {
    return this.paymentService.findByOrder(orderId);
  }

  @Get('marketplace/payments/:id')
  getPayment(@Param('id') id: string) {
    return this.paymentService.findById(id);
  }

  @Patch('marketplace/payments/:id/cancel')
  @HttpCode(200)
  cancelPayment(@Param('id') id: string) {
    return this.paymentService.cancel(id);
  }

  @Patch('marketplace/payments/:id/refund')
  @HttpCode(200)
  refundPayment(@Param('id') id: string) {
    return this.paymentService.refund(id);
  }
}
