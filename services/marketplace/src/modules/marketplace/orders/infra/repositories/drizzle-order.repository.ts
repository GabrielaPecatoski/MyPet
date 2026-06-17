import {
  type DeliveryMethod,
  Order,
  type OrderStatus,
} from "@market/orders/domain/models/order.entity";
import type { OrderRepository } from "@market/orders/domain/repositories/order-repository.interface";
import {
  orderItemsSchema,
  ordersSchema,
} from "@market/orders/infra/database/schemas/order.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { desc, eq } from "drizzle-orm";

@Injectable()
export class DrizzleOrderRepository implements OrderRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async create(order: Order): Promise<string> {
    const [inserted] = await this.drizzleService.db
      .insert(ordersSchema)
      .values({
        userId: order.userId,
        establishmentId: order.establishmentId ?? null,
        total: order.total,
        status: order.status,
        deliveryMethod: order.deliveryMethod,
        deliveryAddress: order.deliveryAddress ?? null,
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

    return inserted.id;
  }

  async findByUserId(userId: string): Promise<Order[]> {
    const orders = await this.drizzleService.db
      .select()
      .from(ordersSchema)
      .where(eq(ordersSchema.userId, userId))
      .orderBy(desc(ordersSchema.createdAt));
    return this.withItems(orders);
  }

  async findByEstablishmentId(establishmentId: string): Promise<Order[]> {
    const orders = await this.drizzleService.db
      .select()
      .from(ordersSchema)
      .where(eq(ordersSchema.establishmentId, establishmentId))
      .orderBy(desc(ordersSchema.createdAt));
    return this.withItems(orders);
  }

  async findById(id: string): Promise<Order | null> {
    const [o] = await this.drizzleService.db
      .select()
      .from(ordersSchema)
      .where(eq(ordersSchema.id, id))
      .limit(1);
    if (!o) return null;
    const items = await this.drizzleService.db
      .select()
      .from(orderItemsSchema)
      .where(eq(orderItemsSchema.orderId, o.id));
    return Order.restore({ ...o, status: o.status as OrderStatus, items });
  }

  async updateStatus(id: string, status: OrderStatus): Promise<void> {
    await this.drizzleService.db
      .update(ordersSchema)
      .set({ status })
      .where(eq(ordersSchema.id, id));
  }

  async updateDelivery(
    id: string,
    deliveryMethod: DeliveryMethod,
    deliveryAddress?: string,
  ): Promise<void> {
    await this.drizzleService.db
      .update(ordersSchema)
      .set({ deliveryMethod, deliveryAddress: deliveryAddress ?? null })
      .where(eq(ordersSchema.id, id));
  }

  private async withItems(
    orders: (typeof ordersSchema.$inferSelect)[],
  ): Promise<Order[]> {
    const result: Order[] = [];
    for (const o of orders) {
      const items = await this.drizzleService.db
        .select()
        .from(orderItemsSchema)
        .where(eq(orderItemsSchema.orderId, o.id));
      result.push(
        Order.restore({ ...o, status: o.status as OrderStatus, items })!,
      );
    }
    return result;
  }
}
