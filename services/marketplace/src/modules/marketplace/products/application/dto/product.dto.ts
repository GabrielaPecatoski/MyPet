import type { Product } from "@market/products/domain/models/product.entity";
import { ApiProperty, ApiPropertyOptional } from "@nestjs/swagger";

export class ProductDto {
  @ApiProperty() id: string | undefined;
  @ApiPropertyOptional() establishmentId?: string;
  @ApiProperty() name: string;
  @ApiProperty() brand: string;
  @ApiProperty() price: number;
  @ApiProperty() unit: string;
  @ApiProperty() category: string;
  @ApiProperty() description: string;
  @ApiProperty() stock: number;
  @ApiPropertyOptional() imageUrl?: string;
  @ApiProperty() active: boolean;

  private constructor(p: Product) {
    this.id = p.id;
    this.establishmentId = p.establishmentId;
    this.name = p.name;
    this.brand = p.brand;
    this.price = p.price;
    this.unit = p.unit;
    this.category = p.category;
    this.description = p.description;
    this.stock = p.stock;
    this.imageUrl = p.imageUrl;
    this.active = p.active;
  }

  static fromProduct(p: Product | null): ProductDto | null {
    if (!p) return null;
    return new ProductDto(p);
  }
}
