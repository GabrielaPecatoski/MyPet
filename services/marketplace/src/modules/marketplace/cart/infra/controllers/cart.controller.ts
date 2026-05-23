import { AddCartItemDto } from "@market/cart/application/dto/add-cart-item.dto";
import { CartItemDto } from "@market/cart/application/dto/cart-item.dto";
import { UpdateCartItemDto } from "@market/cart/application/dto/update-cart-item.dto";
import { CartService } from "@market/cart/application/services/cart.service";
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
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOkResponse,
  ApiOperation,
  ApiTags,
} from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";

@ApiTags("marketplace/cart")
@ApiBearerAuth()
@Controller("marketplace/cart")
export class CartController {
  constructor(private readonly cartService: CartService) {}

  @Get(":userId")
  @RequirePermissions(Permission.CART_READ)
  @ApiOperation({ summary: "Listar itens do carrinho" })
  @ApiOkResponse({ type: [CartItemDto] })
  async getCart(@Param("userId") userId: string): Promise<CartItemDto[]> {
    return this.cartService.findByUser(userId);
  }

  @Get(":userId/:productId")
  @RequirePermissions(Permission.CART_READ)
  @ApiOperation({ summary: "Buscar item do carrinho por produto" })
  @ApiOkResponse({ type: CartItemDto })
  async getItem(
    @Param("userId") userId: string,
    @Param("productId") productId: string,
  ): Promise<CartItemDto> {
    return this.cartService.getItem(userId, productId);
  }

  @Post(":userId")
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Adicionar item ao carrinho" })
  @ApiOkResponse({ type: CartItemDto })
  async addItem(
    @Param("userId") userId: string,
    @Body() body: AddCartItemDto,
  ): Promise<void> {
    return this.cartService.addItem(userId, body.productId, body.quantity);
  }

  @Patch(":userId/:productId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Atualizar quantidade de item no carrinho" })
  @ApiNoContentResponse({ description: "Quantidade atualizada" })
  async updateItem(
    @Param("userId") userId: string,
    @Param("productId") productId: string,
    @Body() body: UpdateCartItemDto,
  ): Promise<void> {
    return this.cartService.updateItem(userId, productId, body.quantity);
  }

  @Delete(":userId/:productId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Remover item do carrinho" })
  @ApiNoContentResponse({ description: "Item removido" })
  async removeItem(
    @Param("userId") userId: string,
    @Param("productId") productId: string,
  ): Promise<void> {
    return this.cartService.removeItem(userId, productId);
  }

  @Delete(":userId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Limpar carrinho" })
  @ApiNoContentResponse({ description: "Carrinho limpo" })
  async clearCart(@Param("userId") userId: string): Promise<void> {
    return this.cartService.clearCart(userId);
  }
}
