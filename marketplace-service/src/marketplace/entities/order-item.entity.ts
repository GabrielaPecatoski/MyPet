import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Order } from './order.entity';

@Entity('order_items')
export class OrderItem {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'order_id' }) orderId: string;
  @ManyToOne(() => Order, order => order.items, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'order_id' }) order: Order;
  @Column({ name: 'product_id' }) productId: string;
  @Column({ name: 'product_name' }) productName: string;
  @Column({ type: 'decimal', precision: 10, scale: 2 }) price: number;
  @Column() quantity: number;
}
