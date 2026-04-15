import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { OrderItem } from './order-item.entity';

@Entity('orders')
export class Order {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ type: 'decimal', precision: 10, scale: 2 }) total: number;
  @Column({ type: 'varchar', default: 'PENDENTE' }) status: 'PENDENTE' | 'CONFIRMADO' | 'ENTREGUE';
  @OneToMany(() => OrderItem, item => item.order, { cascade: true, eager: true }) items: OrderItem[];
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
