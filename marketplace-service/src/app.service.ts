import { Injectable, NotFoundException } from '@nestjs/common';
import * as crypto from 'crypto';

export interface Product {
  id: string;
  name: string;
  brand: string;
  price: number;
  unit: string;
  category: string;
  description: string;
  stock: number;
  imageUrl?: string;
}

export interface CartItem {
  productId: string;
  quantity: number;
  product: Product;
}

export interface Order {
  id: string;
  userId: string;
  items: CartItem[];
  total: number;
  status: 'PENDING' | 'CONFIRMED' | 'DELIVERED';
  createdAt: string;
}

@Injectable()
export class AppService {
  private products: Product[] = [
    { id: 'prod-001', name: 'Areia Sanitária Gatos', brand: 'PetLove', price: 32.90, unit: '4kg', category: 'Higiene', description: 'Areia sanitária de alta absorção', stock: 50 },
    { id: 'prod-002', name: 'Areia Sanitária Gatos', brand: 'PetLove', price: 28.90, unit: '3kg', category: 'Higiene', description: 'Areia sanitária econômica', stock: 30 },
    { id: 'prod-003', name: 'Ração Premium Cães', brand: 'Royal Canin', price: 89.90, unit: '3kg', category: 'Alimentação', description: 'Ração premium para cães adultos', stock: 20 },
    { id: 'prod-004', name: 'Shampoo Pet', brand: 'PetShop Brasil', price: 24.90, unit: '500ml', category: 'Higiene', description: 'Shampoo neutro para pets', stock: 40 },
    { id: 'prod-005', name: 'Coleira Anti-Pulga', brand: 'Seresto', price: 45.00, unit: 'Un', category: 'Saúde', description: 'Coleira anti-pulga 8 meses de proteção', stock: 15 },
    { id: 'prod-006', name: 'Brinquedo Corda', brand: 'PetFun', price: 19.90, unit: 'Un', category: 'Brinquedos', description: 'Brinquedo de corda para cães', stock: 60 },
    { id: 'prod-007', name: 'Ração Gatos Sênior', brand: 'Purina', price: 75.00, unit: '2kg', category: 'Alimentação', description: 'Ração especial para gatos sênior', stock: 25 },
    { id: 'prod-008', name: 'Comedouro Inox', brand: 'PetLife', price: 35.00, unit: 'Un', category: 'Acessórios', description: 'Comedouro de inox antiferrugem', stock: 35 },
  ];

  private carts: Map<string, CartItem[]> = new Map();
  private orders: Order[] = [];

  findAllProducts(search?: string): Product[] {
    if (!search) return this.products;
    const q = search.toLowerCase();
    return this.products.filter(
      (p) => p.name.toLowerCase().includes(q) || p.brand.toLowerCase().includes(q) || p.category.toLowerCase().includes(q),
    );
  }

  findProductById(id: string): Product {
    const p = this.products.find((p) => p.id === id);
    if (!p) throw new NotFoundException('Produto não encontrado');
    return p;
  }

  createProduct(data: Omit<Product, 'id'>): Product {
    const product: Product = { ...data, id: crypto.randomUUID() };
    this.products.push(product);
    return product;
  }

  updateProduct(id: string, data: Partial<Product>): Product {
    const idx = this.products.findIndex((p) => p.id === id);
    if (idx === -1) throw new NotFoundException('Produto não encontrado');
    this.products[idx] = { ...this.products[idx], ...data };
    return this.products[idx];
  }

  deleteProduct(id: string): void {
    const idx = this.products.findIndex((p) => p.id === id);
    if (idx === -1) throw new NotFoundException('Produto não encontrado');
    this.products.splice(idx, 1);
  }

  getCart(userId: string): CartItem[] {
    return this.carts.get(userId) ?? [];
  }

  addToCart(userId: string, productId: string, quantity: number): CartItem[] {
    const product = this.findProductById(productId);
    const cart = this.carts.get(userId) ?? [];
    const existing = cart.find((c) => c.productId === productId);
    if (existing) {
      existing.quantity += quantity;
    } else {
      cart.push({ productId, quantity, product });
    }
    this.carts.set(userId, cart);
    return cart;
  }

  removeFromCart(userId: string, productId: string): CartItem[] {
    const cart = (this.carts.get(userId) ?? []).filter((c) => c.productId !== productId);
    this.carts.set(userId, cart);
    return cart;
  }

  clearCart(userId: string): void {
    this.carts.delete(userId);
  }

  checkout(userId: string): Order {
    const cart = this.carts.get(userId);
    if (!cart || cart.length === 0) throw new NotFoundException('Carrinho vazio');
    const total = cart.reduce((sum, c) => sum + c.product.price * c.quantity, 0);
    const order: Order = {
      id: crypto.randomUUID(),
      userId,
      items: [...cart],
      total,
      status: 'CONFIRMED',
      createdAt: new Date().toISOString(),
    };
    this.orders.push(order);
    this.carts.delete(userId);
    return order;
  }

  getUserOrders(userId: string): Order[] {
    return this.orders.filter((o) => o.userId === userId);
  }
}
