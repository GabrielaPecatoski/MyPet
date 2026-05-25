import { ApiProperty } from "@nestjs/swagger";

export interface CartItemEnriched {
  id: string;
  userId: string;
  productId: string;
  productName: string;
  price: number;
  imageUrl?: string | null;
  quantity: number;
}

export class CartItemDto {
  @ApiProperty()
  id!: string;

  @ApiProperty()
  productId!: string;

  @ApiProperty()
  productName!: string;

  @ApiProperty()
  price!: number;

  @ApiProperty({ required: false })
  imageUrl?: string;

  @ApiProperty()
  quantity!: number;

  @ApiProperty()
  subtotal!: number;

  static from(item: CartItemEnriched): CartItemDto {
    const dto = new CartItemDto();
    dto.id = item.id;
    dto.productId = item.productId;
    dto.productName = item.productName;
    dto.price = item.price;
    dto.imageUrl = item.imageUrl ?? undefined;
    dto.quantity = item.quantity;
    dto.subtotal = +(item.price * item.quantity).toFixed(2);
    return dto;
  }
}
