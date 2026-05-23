import { CreateProductDto } from "@market/products/application/dto/create-product.dto";
import { ProductDto } from "@market/products/application/dto/product.dto";
import { ProductService } from "@market/products/application/services/product.service";
import { CartService } from "@market/cart/application/services/cart.service";
import { OrderService } from "@market/orders/application/services/order.service";
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
  Query,
} from "@nestjs/common";
import {
  ApiBearerAuth,
  ApiNoContentResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
import { CurrentUser } from "@shared/infra/decorators/current-user.decorator";
import type { AuthenticatedUser } from "@shared/infra/auth/interfaces/authenticated-user.interface";
import { HateoasItem } from "@shared/infra/hateoas";

@ApiTags("marketplace/products")
@Controller("marketplace/products")
export class ProductsController {
  constructor(private readonly productService: ProductService) {}

  @Get()
  @Public()
  @ApiOperation({ summary: "Listar produtos" })
  @ApiQuery({ name: "search", required: false })
  async findAll(@Query("search") search?: string): Promise<ProductDto[]> {
    return this.productService.findAll(search);
  }

  @Get("establishment/:id")
  @ApiBearerAuth()
  @RequirePermissions(Permission.PRODUCTS_READ)
  @ApiOperation({ summary: "Listar produtos do estabelecimento" })
  async findByEstablishment(@Param("id") id: string): Promise<ProductDto[]> {
    return this.productService.findByEstablishment(id);
  }

  @Get(":id")
  @Public()
  @ApiOperation({ summary: "Buscar produto por ID" })
  @HateoasItem<ProductDto>({
    basePath: "/v1/marketplace/products",
    itemLinks: (item) => ({
      self: { href: `/v1/marketplace/products/${item.id}`, method: "GET" },
      update: { href: `/v1/marketplace/products/${item.id}`, method: "PATCH" },
    }),
  })
  async findById(@Param("id") id: string) {
    return this.productService.findById(id);
  }

  @Post()
  @ApiBearerAuth()
  @RequirePermissions(Permission.PRODUCTS_WRITE)
  @ApiOperation({ summary: "Criar produto" })
  async create(@Body() body: CreateProductDto) {
    return this.productService.create(body);
  }

  @Patch(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.PRODUCTS_WRITE)
  @ApiOperation({ summary: "Atualizar produto" })
  @ApiNoContentResponse({ description: "Produto atualizado" })
  async update(@Param("id") id: string, @Body() body: Partial<CreateProductDto>) {
    return this.productService.update(id, body);
  }

  @Delete(":id")
  @HttpCode(HttpStatus.NO_CONTENT)
  @ApiBearerAuth()
  @RequirePermissions(Permission.PRODUCTS_DELETE)
  @ApiOperation({ summary: "Remover produto" })
  @ApiNoContentResponse({ description: "Produto removido" })
  async remove(@Param("id") id: string) {
    return this.productService.remove(id);
  }
}

@ApiTags("marketplace/cart")
@ApiBearerAuth()
@Controller("marketplace/cart")
export class CartController {
  constructor(
    private readonly cartService: CartService,
    private readonly orderService: OrderService,
  ) {}

  @Get(":userId")
  @RequirePermissions(Permission.CART_READ)
  @ApiOperation({ summary: "Listar itens do carrinho" })
  async getCart(@Param("userId") userId: string) {
    return this.cartService.findByUser(userId);
  }

  @Post(":userId")
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Adicionar item ao carrinho" })
  async addItem(
    @Param("userId") userId: string,
    @Body() body: { productId: string; quantity: number },
  ) {
    return this.cartService.addItem(userId, body.productId, body.quantity);
  }

  @Patch(":userId/:productId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Atualizar quantidade de item no carrinho" })
  async updateItem(
    @Param("userId") userId: string,
    @Param("productId") productId: string,
    @Body() body: { quantity: number },
  ) {
    return this.cartService.updateItem(userId, productId, body.quantity);
  }

  @Delete(":userId/:productId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Remover item do carrinho" })
  async removeItem(
    @Param("userId") userId: string,
    @Param("productId") productId: string,
  ) {
    return this.cartService.removeItem(userId, productId);
  }

  @Delete(":userId")
  @HttpCode(HttpStatus.NO_CONTENT)
  @RequirePermissions(Permission.CART_WRITE)
  @ApiOperation({ summary: "Limpar carrinho" })
  async clearCart(@Param("userId") userId: string) {
    return this.cartService.clearCart(userId);
  }
}

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
