import { CartItemDto } from "@market/cart/application/dto/cart-item.dto";
import {
  CART_REPOSITORY,
  type CartRepository,
} from "@market/cart/domain/repositories/cart-repository.interface";
import { Inject, Injectable, NotFoundException } from "@nestjs/common";

@Injectable()
export class CartService {
  constructor(
    @Inject(CART_REPOSITORY)
    private readonly cartRepo: CartRepository,
  ) {}

  async addItem(
    userId: string,
    productId: string,
    quantity: number,
  ): Promise<void> {
    await this.cartRepo.addItem({ userId, productId, quantity });
  }

  async updateItem(
    userId: string,
    productId: string,
    quantity: number,
  ): Promise<void> {
    await this.cartRepo.updateItem(userId, productId, quantity);
  }

  async removeItem(userId: string, productId: string): Promise<void> {
    await this.cartRepo.removeItem(userId, productId);
  }

  async clearCart(userId: string): Promise<void> {
    await this.cartRepo.clearCart(userId);
  }

  async findByUser(userId: string): Promise<CartItemDto[]> {
    const items = await this.cartRepo.findByUserId(userId);
    return items.map((item) => CartItemDto.from(item));
  }

  async getItem(userId: string, productId: string): Promise<CartItemDto> {
    const items = await this.cartRepo.findByUserId(userId);
    const found = items.find((i) => i.productId === productId);
    if (!found) throw new NotFoundException("Item não encontrado no carrinho");
    return CartItemDto.from(found);
  }
}
