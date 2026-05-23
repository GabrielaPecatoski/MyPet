import type { CartItemEnriched } from "@market/cart/application/dto/cart-item.dto";

export const CART_REPOSITORY = Symbol("CART_REPOSITORY");

export interface CartItemInput {
  userId: string;
  productId: string;
  quantity: number;
}

export interface CartRepository {
  addItem(item: CartItemInput): Promise<void>;
  updateItem(userId: string, productId: string, quantity: number): Promise<void>;
  removeItem(userId: string, productId: string): Promise<void>;
  clearCart(userId: string): Promise<void>;
  findByUserId(userId: string): Promise<CartItemEnriched[]>;
}
