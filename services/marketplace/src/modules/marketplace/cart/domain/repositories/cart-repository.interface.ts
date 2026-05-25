export const CART_REPOSITORY = Symbol("CART_REPOSITORY");

export interface CartItem {
  id?: string;
  userId: string;
  productId: string;
  quantity: number;
}

export interface CartRepository {
  addItem(item: CartItem): Promise<void>;
  updateItem(userId: string, productId: string, quantity: number): Promise<void>;
  removeItem(userId: string, productId: string): Promise<void>;
  clearCart(userId: string): Promise<void>;
  findByUserId(userId: string): Promise<CartItem[]>;
}
