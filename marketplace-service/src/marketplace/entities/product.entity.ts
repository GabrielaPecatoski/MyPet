import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('products')
export class Product {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column() name: string;
  @Column({ nullable: true }) brand: string;
  @Column({ type: 'decimal', precision: 10, scale: 2 }) price: number;
  @Column({ nullable: true }) unit: string;
  @Column({ nullable: true }) category: string;
  @Column({ nullable: true }) description: string;
  @Column({ default: 0 }) stock: number;
  @Column({ name: 'image_url', nullable: true }) imageUrl: string;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
