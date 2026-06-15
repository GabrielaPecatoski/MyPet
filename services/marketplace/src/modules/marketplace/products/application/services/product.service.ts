import { CreateProductDto } from "@market/products/application/dto/create-product.dto";
import { ProductDto } from "@market/products/application/dto/product.dto";
import { Product } from "@market/products/domain/models/product.entity";
import {
  PRODUCT_REPOSITORY,
  type ProductRepository,
} from "@market/products/domain/repositories/product-repository.interface";
import { Inject, Injectable, NotFoundException } from "@nestjs/common";
import type { PaginatedResult, PaginationParams } from "@shared/infra/hateoas";

@Injectable()
export class ProductService {
  constructor(
    @Inject(PRODUCT_REPOSITORY)
    private readonly repo: ProductRepository,
  ) {}

  async create(dto: CreateProductDto): Promise<ProductDto> {
    const product = Product.restore({
      establishmentId: dto.establishmentId,
      name: dto.name,
      brand: dto.brand ?? "",
      price: dto.price,
      unit: dto.unit ?? "Un",
      category: dto.category ?? "",
      description: dto.description ?? "",
      stock: dto.stock ?? 0,
      imageUrl: dto.imageUrl,
      active: true,
    })!;
    const created = await this.repo.create(product);
    return ProductDto.fromProduct(created)!;
  }

  async findAll(search?: string): Promise<ProductDto[]> {
    const rows = await this.repo.findAll(search);
    return rows.map((p) => ProductDto.fromProduct(p)!);
  }

  async findByEstablishment(establishmentId: string): Promise<ProductDto[]> {
    const rows = await this.repo.findByEstablishment(establishmentId);
    return rows.map((p) => ProductDto.fromProduct(p)!);
  }

  async listPaginated(
    params: PaginationParams,
    search?: string,
  ): Promise<PaginatedResult<ProductDto>> {
    const { rows, total } = await this.repo.findAllPaginated(params, search);
    return {
      data: rows.map((p) => ProductDto.fromProduct(p)!),
      total,
      page: params.page,
      limit: params.limit,
    };
  }

  async findById(id: string): Promise<ProductDto | null> {
    return ProductDto.fromProduct(await this.repo.findById(id));
  }

  async update(id: string, dto: Partial<CreateProductDto>): Promise<void> {
    const product = await this.repo.findById(id);
    if (!product) throw new NotFoundException("Produto não encontrado");
    if (dto.name) product.withName(dto.name);
    if (dto.brand !== undefined) product.withBrand(dto.brand);
    if (dto.price !== undefined) product.withPrice(dto.price);
    if (dto.unit) product.withUnit(dto.unit);
    if (dto.category !== undefined) product.withCategory(dto.category);
    if (dto.description !== undefined) product.withDescription(dto.description);
    if (dto.stock !== undefined) product.withStock(dto.stock);
    if (dto.imageUrl !== undefined) product.withImageUrl(dto.imageUrl);
    if (dto.active !== undefined) product.withActive(dto.active);
    await this.repo.update(product);
  }

  async remove(id: string): Promise<void> {
    const product = await this.repo.findById(id);
    if (!product) throw new NotFoundException("Produto não encontrado");
    await this.repo.delete(id);
  }
}
