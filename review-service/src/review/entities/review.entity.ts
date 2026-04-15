import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('reviews')
export class Review {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'user_name', nullable: true }) userName: string;
  @Column({ name: 'establishment_id' }) establishmentId: string;
  @Column({ name: 'booking_id', nullable: true }) bookingId: string;
  @Column({ type: 'int' }) rating: number;
  @Column({ nullable: true }) comment: string;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
