import type { Order } from "@market/orders/domain/models/order.entity";
import { ApiProperty } from "@nestjs/swagger";

export class OrderDto {
  @ApiProperty() id: string | undefined;
  @ApiProperty() userId: string;
  @ApiProperty() total: number;
  @ApiProperty() status: string;
  @ApiProperty() items: { productId: string; quantity: number; price: number }[];
  @ApiProperty() createdAt: Date | undefined;

  private constructor(o: Order) {
    this.id = o.id;
    this.userId = o.userId;
    this.total = o.total;
    this.status = o.status;
    this.items = o.items;
    this.createdAt = o.createdAt;
  }

  static fromOrder(o: Order | null): OrderDto | null {
    if (!o) return null;
    return new OrderDto(o);
  }
}
