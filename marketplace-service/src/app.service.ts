import { Inject, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { ClientProxy } from '@nestjs/microservices';
import { PrismaService } from './prisma.service';
import { RABBITMQ_CLIENT } from './constants';
import { EVENTS } from './events/events.constants';

@Injectable()
export class AppService {
  private readonly logger = new Logger(AppService.name);

  constructor(
    private readonly prisma: PrismaService,
    @Inject(RABBITMQ_CLIENT) private readonly rabbitClient: ClientProxy,
  ) {}

  async findAllProducts(search?: string) {
    return this.prisma.product.findMany({
      where: search
        ? {
            OR: [
              { name: { contains: search, mode: 'insensitive' } },
              { brand: { contains: search, mode: 'insensitive' } },
              { category: { contains: search, mode: 'insensitive' } },
            ],
          }
        : undefined,
    });
  }

  async findProductById(id: string) {
    const p = await this.prisma.product.findUnique({ where: { id } });
    if (!p) throw new NotFoundException('Produto não encontrado');
    return p;
  }

  async findProductsByEstab(estabId: string) {
    return this.prisma.product.findMany({ where: { establishmentId: estabId } });
  }

  async createProduct(data: any) {
    return this.prisma.product.create({ data });
  }

  async createProductForEstab(estabId: string, data: any) {
    return this.prisma.product.create({ data: { ...data, establishmentId: estabId } });
  }

  async updateProduct(id: string, data: any) {
    await this.findProductById(id);
    return this.prisma.product.update({ where: { id }, data });
  }

  async deleteProduct(id: string) {
    await this.findProductById(id);
    await this.prisma.product.delete({ where: { id } });
  }

  async getCart(userId: string) {
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
    const item = await this.prisma.cartItem.findUnique({
      where: { userId_productId: { userId, productId } },
    });
    if (!item) throw new NotFoundException('Item não encontrado no carrinho');
    await this.prisma.cartItem.update({
      where: { userId_productId: { userId, productId } },
      data: { quantity },
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

    const total = cartItems.reduce((sum, item) => sum + item.product.price * item.quantity, 0);

    const order = await this.prisma.order.create({
      data: {
        userId,
        total,
        status: 'CONFIRMED',
        items: {
          create: cartItems.map((item) => ({
            productId: item.productId,
            quantity: item.quantity,
            price: item.product.price,
          })),
        },
      },
      include: { items: { include: { product: true } } },
    });

    await this.prisma.cartItem.deleteMany({ where: { userId } });

    try {
      this.rabbitClient.emit(EVENTS.ORDER_CREATED, {
        orderId: order.id,
        userId: order.userId,
        total: order.total,
        itemCount: order.items.length,
        createdAt: order.createdAt.toISOString(),
      });
    } catch (err) {
      this.logger.warn(`Falha ao emitir ORDER_CREATED: ${err}`);
    }

    return order;
  }

  async getUserOrders(userId: string) {
    return this.prisma.order.findMany({
      where: { userId },
      include: { items: { include: { product: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }
}
