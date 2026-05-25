import { CART_REPOSITORY, type CartRepository } from "@market/cart/domain/repositories/cart-repository.interface";
import { Inject, Injectable } from "@nestjs/common";

export interface CartItemView {
  userId: string;
  productId: string;
  quantity: number;
}

@Injectable()
export class CartService {
  constructor(
    @Inject(CART_REPOSITORY)
    private readonly cartRepo: CartRepository,
  ) {}

  async addItem(userId: string, productId: string, quantity: number): Promise<void> {
    await this.cartRepo.addItem({ userId, productId, quantity });
  }

  async updateItem(userId: string, productId: string, quantity: number): Promise<void> {
    await this.cartRepo.updateItem(userId, productId, quantity);
  }

  async removeItem(userId: string, productId: string): Promise<void> {
    await this.cartRepo.removeItem(userId, productId);
  }

  async clearCart(userId: string): Promise<void> {
    await this.cartRepo.clearCart(userId);
  }

  async findByUser(userId: string): Promise<CartItemView[]> {
    return this.cartRepo.findByUserId(userId);
  }
}
