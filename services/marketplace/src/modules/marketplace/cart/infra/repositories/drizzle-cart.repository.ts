import type { CartItemEnriched } from "@market/cart/application/dto/cart-item.dto";
import type {
  CartItemInput,
  CartRepository,
} from "@market/cart/domain/repositories/cart-repository.interface";
import { cartItemsSchema } from "@market/cart/infra/database/schemas/cart-item.schema";
import { productsSchema } from "@market/products/infra/database/schemas/product.schema";
import { Injectable } from "@nestjs/common";
import { DrizzleService } from "@shared/infra/database/drizzle.service";
import { and, eq } from "drizzle-orm";

@Injectable()
export class DrizzleCartRepository implements CartRepository {
  constructor(private readonly drizzleService: DrizzleService) {}

  async addItem(item: CartItemInput): Promise<void> {
    await this.drizzleService.db
      .insert(cartItemsSchema)
      .values({
        userId: item.userId,
        productId: item.productId,
        quantity: item.quantity,
      })
      .onConflictDoUpdate({
        target: [cartItemsSchema.userId, cartItemsSchema.productId],
        set: { quantity: item.quantity },
      });
  }

  async updateItem(
    userId: string,
    productId: string,
    quantity: number,
  ): Promise<void> {
    await this.drizzleService.db
      .update(cartItemsSchema)
      .set({ quantity })
      .where(
        and(
          eq(cartItemsSchema.userId, userId),
          eq(cartItemsSchema.productId, productId),
        ),
      );
  }

  async removeItem(userId: string, productId: string): Promise<void> {
    await this.drizzleService.db
      .delete(cartItemsSchema)
      .where(
        and(
          eq(cartItemsSchema.userId, userId),
          eq(cartItemsSchema.productId, productId),
        ),
      );
  }

  async clearCart(userId: string): Promise<void> {
    await this.drizzleService.db
      .delete(cartItemsSchema)
      .where(eq(cartItemsSchema.userId, userId));
  }

  async findByUserId(userId: string): Promise<CartItemEnriched[]> {
    return this.drizzleService.db
      .select({
        id: cartItemsSchema.id,
        userId: cartItemsSchema.userId,
        productId: cartItemsSchema.productId,
        quantity: cartItemsSchema.quantity,
        productName: productsSchema.name,
        price: productsSchema.price,
        imageUrl: productsSchema.imageUrl,
      })
      .from(cartItemsSchema)
      .innerJoin(
        productsSchema,
        eq(cartItemsSchema.productId, productsSchema.id),
      )
      .where(eq(cartItemsSchema.userId, userId));
  }
}
