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
import { MarketplaceService } from './marketplace.service';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

@Controller('marketplace')
export class MarketplaceController {
  constructor(private readonly marketplaceService: MarketplaceService) {}

  // --- Products ---

  @Get('products')
  findAll(@Query('search') search?: string) {
    return this.marketplaceService.findAll(search);
  }

  @Get('products/:id')
  findById(@Param('id') id: string) {
    return this.marketplaceService.findById(id);
  }

  @Post('products')
  create(@Body() dto: CreateProductDto) {
    return this.marketplaceService.create(dto);
  }

  @Patch('products/:id')
  update(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.marketplaceService.update(id, dto);
  }

  @Delete('products/:id')
  @HttpCode(204)
  remove(@Param('id') id: string) {
    return this.marketplaceService.remove(id);
  }

  // --- Cart ---

  @Get('cart/:userId')
  getCart(@Param('userId') userId: string) {
    return this.marketplaceService.getCart(userId);
  }

  @Post('cart/:userId')
  addToCart(
    @Param('userId') userId: string,
    @Body() body: { productId: string; quantity: number },
  ) {
    return this.marketplaceService.addToCart(userId, body);
  }

  @Delete('cart/:userId/:productId')
  @HttpCode(204)
  removeFromCart(
    @Param('userId') userId: string,
    @Param('productId') productId: string,
  ) {
    return this.marketplaceService.removeFromCart(userId, productId);
  }

  // --- Orders ---

  @Post('orders/:userId')
  checkout(@Param('userId') userId: string) {
    return this.marketplaceService.checkout(userId);
  }

  @Get('orders/:userId')
  findByUser(@Param('userId') userId: string) {
    return this.marketplaceService.findByUser(userId);
  }
}
