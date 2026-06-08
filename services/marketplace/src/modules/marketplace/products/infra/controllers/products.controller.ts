import { CreateProductDto } from "@market/products/application/dto/create-product.dto";
import { ProductDto } from "@market/products/application/dto/product.dto";
import { ProductService } from "@market/products/application/services/product.service";
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
  ApiCreatedResponse,
  ApiNoContentResponse,
  ApiOperation,
  ApiQuery,
  ApiTags,
} from "@nestjs/swagger";
import { Permission } from "@shared/domain/enums/permission.enum";
import { RequirePermissions } from "@shared/infra/decorators/permissions.decorator";
import { Public } from "@shared/infra/decorators/public.decorator";
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
@HttpCode(HttpStatus.CREATED)
@RequirePermissions(Permission.PRODUCTS_WRITE)
@ApiOperation({ summary: "Criar produto" })
@ApiCreatedResponse({ description: "Produto criado", type: ProductDto })
async create(@Body() body: CreateProductDto): Promise<ProductDto> {
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
