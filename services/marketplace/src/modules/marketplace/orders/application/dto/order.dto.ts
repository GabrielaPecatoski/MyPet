import type { Order } from "@market/orders/domain/models/order.entity";
import { ApiProperty } from "@nestjs/swagger";

export class OrderDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() userId: string;
  @ApiProperty() establishmentId: string | undefined;
  @ApiProperty() total: number;
  @ApiProperty() status: string;
  @ApiProperty() deliveryMethod: string;
  @ApiProperty() deliveryAddress: string | undefined;
  @ApiProperty() items: {
    productId: string;
    quantity: number;
    price: number;
  }[];
  @ApiProperty() createdAt: Date | undefined;

  private constructor(o: Order) {
    this.id = o.id;
    this.userId = o.userId;
    this.establishmentId = o.establishmentId;
    this.total = o.total;
    this.status = o.status;
    this.deliveryMethod = o.deliveryMethod;
    this.deliveryAddress = o.deliveryAddress;
    this.items = o.items;
    this.createdAt = o.createdAt;
  }

  static fromOrder(o: Order | null): OrderDto | null {
    if (!o) return null;
    return new OrderDto(o);
  }
}
