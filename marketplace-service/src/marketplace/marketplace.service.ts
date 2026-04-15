import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Product } from './entities/product.entity';
import { Order } from './entities/order.entity';
import { OrderItem } from './entities/order-item.entity';
import { CreateProductDto } from './dto/create-product.dto';
import { UpdateProductDto } from './dto/update-product.dto';

export interface CartItem {
  productId: string;
  productName: string;
  price: number;
  quantity: number;
}

@Injectable()
export class MarketplaceService {
  private carts = new Map<string, CartItem[]>();

  constructor(
    @InjectRepository(Product)
    private readonly productRepo: Repository<Product>,
    @InjectRepository(Order)
    private readonly orderRepo: Repository<Order>,
  ) {}

  // --- Products ---

  findAll(search?: string): Promise<Product[]> {
    if (search) {
      return this.productRepo
        .createQueryBuilder('p')
        .where('LOWER(p.name) LIKE :search', { search: `%${search.toLowerCase()}%` })
        .getMany();
    }
    return this.productRepo.find();
  }

  async findById(id: string): Promise<Product> {
    const product = await this.productRepo.findOne({ where: { id } });
    if (!product) {
      throw new NotFoundException(`Product with id "${id}" not found`);
    }
    return product;
  }

  create(dto: CreateProductDto): Promise<Product> {
    const product = this.productRepo.create(dto);
    return this.productRepo.save(product);
  }

  async update(id: string, dto: UpdateProductDto): Promise<Product> {
    const product = await this.findById(id);
    Object.assign(product, dto);
    return this.productRepo.save(product);
  }

  async remove(id: string): Promise<void> {
    await this.productRepo.delete(id);
  }

  // --- Cart (in-memory) ---

  getCart(userId: string): CartItem[] {
    return this.carts.get(userId) ?? [];
  }

  async addToCart(
    userId: string,
    body: { productId: string; quantity: number },
  ): Promise<CartItem[]> {
    const product = await this.findById(body.productId);
    const cart = this.carts.get(userId) ?? [];
    const existing = cart.find(item => item.productId === body.productId);
    if (existing) {
      existing.quantity += body.quantity;
    } else {
      cart.push({
        productId: product.id,
        productName: product.name,
        price: Number(product.price),
        quantity: body.quantity,
      });
    }
    this.carts.set(userId, cart);
    return cart;
  }

  removeFromCart(userId: string, productId: string): CartItem[] {
    const cart = (this.carts.get(userId) ?? []).filter(
      item => item.productId !== productId,
    );
    this.carts.set(userId, cart);
    return cart;
  }

  // --- Orders ---

  async checkout(userId: string): Promise<Order> {
    const cart = this.carts.get(userId) ?? [];
    const total = cart.reduce((sum, item) => sum + item.price * item.quantity, 0);

    const items: Partial<OrderItem>[] = cart.map(item => ({
      productId: item.productId,
      productName: item.productName,
      price: item.price,
      quantity: item.quantity,
    }));

    const order = this.orderRepo.create({
      userId,
      total,
      status: 'PENDENTE',
      items: items as OrderItem[],
    });

    const saved = await this.orderRepo.save(order);
    this.carts.set(userId, []);
    return saved;
  }

  findByUser(userId: string): Promise<Order[]> {
    return this.orderRepo.find({ where: { userId }, relations: ['items'] });
  }
}
