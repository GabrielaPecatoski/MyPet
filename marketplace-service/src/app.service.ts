import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class AppService {
  constructor(private readonly prisma: PrismaService) {}

  findAllProducts(search?: string) {
    return this.prisma.product.findMany({
      where: search
        ? {
            active: true,
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { brand: { contains: search, mode: 'insensitive' } },
              { category: { contains: search, mode: 'insensitive' } },
            ],
          }
        : { active: true },
      orderBy: { name: 'asc' },
    });
  }

  async findProductById(id: string) {
    const p = await this.prisma.product.findUnique({ where: { id } });
    if (!p) throw new NotFoundException('Produto não encontrado');
    return p;
  }

  createProduct(data: {
    name: string;
    brand?: string;
    price: number;
    unit?: string;
    category?: string;
    description?: string;
    stock?: number;
    imageUrl?: string;
  }) {
    return this.prisma.product.create({ data: { ...data } });
  }

  async updateProduct(
    id: string,
    data: Partial<{
      name: string;
      brand: string;
      price: number;
      unit: string;
      category: string;
      description: string;
      stock: number;
      imageUrl: string;
      active: boolean;
    }>,
  ) {
    await this.findProductById(id);
    return this.prisma.product.update({ where: { id }, data });
  }

  async deleteProduct(id: string) {
    await this.findProductById(id);
    await this.prisma.product.update({
      where: { id },
      data: { active: false },
    });
  }

  getCart(userId: string) {
    return this.prisma.cartItem.findMany({
      where: { userId },
      include: { product: true },
    });
  }

  async addToCart(userId: string, productId: string, quantity: number) {
    await this.findProductById(productId);
    await this.prisma.cartItem.upsert({
      where: { userId_productId: { userId, productId } },
      create: { userId, productId, quantity },
      update: { quantity: { increment: quantity } },
    });
    return this.getCart(userId);
  }

  async updateCartItem(userId: string, productId: string, quantity: number) {
    if (quantity <= 0) {
      return this.removeFromCart(userId, productId);
    }
    await this.prisma.cartItem.upsert({
      where: { userId_productId: { userId, productId } },
      create: { userId, productId, quantity },
      update: { quantity },
    });
    return this.getCart(userId);
  }

  async removeFromCart(userId: string, productId: string) {
    await this.prisma.cartItem.deleteMany({ where: { userId, productId } });
    return this.getCart(userId);
  }

  async clearCart(userId: string) {
    await this.prisma.cartItem.deleteMany({ where: { userId } });
  }

  async checkout(userId: string) {
    const cartItems = await this.prisma.cartItem.findMany({
      where: { userId },
      include: { product: true },
    });
    if (cartItems.length === 0) throw new NotFoundException('Carrinho vazio');

    const total = cartItems.reduce(
      (sum, i) => sum + i.product.price * i.quantity,
      0,
    );

    const order = await this.prisma.order.create({
      data: {
        userId,
        total,
        status: 'CONFIRMED',
        items: {
          create: cartItems.map((i) => ({
            productId: i.productId,
            quantity: i.quantity,
            price: i.product.price,
          })),
        },
      },
      include: { items: { include: { product: true } } },
    });

    await this.prisma.cartItem.deleteMany({ where: { userId } });
    return order;
  }

  getUserOrders(userId: string) {
    return this.prisma.order.findMany({
      where: { userId },
      include: { items: { include: { product: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
