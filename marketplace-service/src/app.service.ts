import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Injectable()
export class AppService {
  private carts: Map<string, { productId: string; quantity: number }[]> =
    new Map();

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

  async getCart(userId: string) {
    const items = this.carts.get(userId) ?? [];
    const products = await Promise.all(
      items.map(async (item) => {
        const product = await this.prisma.product.findUnique({
          where: { id: item.productId },
        });
        return product ? { ...item, product } : null;
      }),
    );
    return products.filter(Boolean);
  }

  async addToCart(userId: string, productId: string, quantity: number) {
    await this.findProductById(productId);
    const cart = this.carts.get(userId) ?? [];
    const existing = cart.find((c) => c.productId === productId);
    if (existing) {
      existing.quantity += quantity;
    } else {
      cart.push({ productId, quantity });
    }
    this.carts.set(userId, cart);
    return this.getCart(userId);
  }

  removeFromCart(userId: string, productId: string) {
    const cart = (this.carts.get(userId) ?? []).filter(
      (c) => c.productId !== productId,
    );
    this.carts.set(userId, cart);
    return this.getCart(userId);
  }

  clearCart(userId: string) {
    this.carts.delete(userId);
  }

  async checkout(userId: string) {
    const cartItems = this.carts.get(userId);
    if (!cartItems || cartItems.length === 0)
      throw new NotFoundException('Carrinho vazio');

    const itemsWithProducts = await Promise.all(
      cartItems.map(async (item) => {
        const product = await this.prisma.product.findUnique({
          where: { id: item.productId },
        });
        if (!product)
          throw new NotFoundException(
            `Produto ${item.productId} não encontrado`,
          );
        return { product, quantity: item.quantity, price: product.price };
      }),
    );

    const total = itemsWithProducts.reduce(
      (sum, i) => sum + i.price * i.quantity,
      0,
    );

    const order = await this.prisma.order.create({
      data: {
        userId,
        total,
        status: 'CONFIRMED',
        items: {
          create: itemsWithProducts.map((i) => ({
            productId: i.product.id,
            quantity: i.quantity,
            price: i.price,
          })),
        },
      },
      include: { items: { include: { product: true } } },
    });

    this.carts.delete(userId);
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
