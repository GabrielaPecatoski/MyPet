import {
  Controller, Get, Post, Patch, Delete,
  Param, Body, Query, HttpCode,
} from '@nestjs/common';
import { AppService } from './app.service';

@Controller()
export class AppController {
  constructor(private readonly appService: AppService) {}

  // ── Products ─────────────────────────────────────────────────────
  @Get('marketplace/products')
  listProducts(@Query('search') search?: string) {
    return this.appService.findAllProducts(search);
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
    this.appService.deleteProduct(id);
  }

  // ── Cart ─────────────────────────────────────────────────────────
  @Get('marketplace/cart/:userId')
  getCart(@Param('userId') userId: string) {
    return this.appService.getCart(userId);
  }

  @Post('marketplace/cart/:userId')
  addToCart(
    @Param('userId') userId: string,
    @Body() body: { productId: string; quantity: number },
  ) {
    return this.appService.addToCart(userId, body.productId, body.quantity ?? 1);
  }

  @Delete('marketplace/cart/:userId/:productId')
  removeFromCart(
    @Param('userId') userId: string,
    @Param('productId') productId: string,
  ) {
    return this.appService.removeFromCart(userId, productId);
  }

  // ── Orders ───────────────────────────────────────────────────────
  @Post('marketplace/orders/:userId')
  checkout(@Param('userId') userId: string) {
    return this.appService.checkout(userId);
  }

  @Get('marketplace/orders/:userId')
  getUserOrders(@Param('userId') userId: string) {
    return this.appService.getUserOrders(userId);
  }
}
