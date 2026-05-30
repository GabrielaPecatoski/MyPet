import type { DeliveryMethod, Order, OrderStatus } from "@market/orders/domain/models/order.entity";

export const ORDER_REPOSITORY = Symbol("ORDER_REPOSITORY");

export interface OrderRepository {
  create(order: Order): Promise<string>;
  findByUserId(userId: string): Promise<Order[]>;
  findByEstablishmentId(establishmentId: string): Promise<Order[]>;
  findById(id: string): Promise<Order | null>;
  updateStatus(id: string, status: OrderStatus): Promise<void>;
  updateDelivery(id: string, deliveryMethod: DeliveryMethod, deliveryAddress?: string): Promise<void>;
}
