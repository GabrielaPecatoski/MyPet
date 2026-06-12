import { Order, type OrderStatus } from "@market/orders/domain/models/order.entity";
import type { OrderRepository } from "@market/orders/domain/repositories/order-repository.interface";
import { orderItemsSchema, ordersSchema } from "@market/orders/infra/database/schemas/order.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { eq } from "drizzle-orm";

@Injectable()
export class DrizzleOrderRepository implements OrderRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(order: Order): Promise<void> {
    const [inserted] = await this.drizzleService.db
      .insert(ordersSchema)
      .values({
        userId: order.userId,
        total: order.total,
        status: order.status,
        createdAt: new Date(),
      })
      .returning({ id: ordersSchema.id });

    if (order.items.length > 0) {
      await this.drizzleService.db.insert(orderItemsSchema).values(
        order.items.map((item) => ({
          orderId: inserted.id,
          productId: item.productId,
          quantity: item.quantity,
          price: item.price,
        })),
      );
    }
  }

  async findByUserId(userId: string): Promise<Order[]> {
    const orders = await this.drizzleService.db
      .select()
      .from(ordersSchema)
      .where(eq(ordersSchema.userId, userId));

    const result: Order[] = [];
    for (const o of orders) {
      const items = await this.drizzleService.db
        .select()
        .from(orderItemsSchema)
        .where(eq(orderItemsSchema.orderId, o.id));
      result.push(Order.restore({ ...o, status: o.status as OrderStatus, items })!);
    }
    return result;
  }

  async findById(id: string): Promise<Order | null> {
    const [o] = await this.drizzleService.db.select().from(ordersSchema).where(eq(ordersSchema.id, id)).limit(1);
    if (!o) return null;
    const items = await this.drizzleService.db.select().from(orderItemsSchema).where(eq(orderItemsSchema.orderId, o.id));
    return Order.restore({ ...o, status: o.status as OrderStatus, items });
  }

  async updateStatus(id: string, status: OrderStatus): Promise<void> {
    await this.drizzleService.db
      .update(ordersSchema)
      .set({ status })
      .where(eq(ordersSchema.id, id));
  }
}
