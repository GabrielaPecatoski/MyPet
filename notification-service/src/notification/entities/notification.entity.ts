import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('notifications')
export class Notification {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ type: 'varchar' })
  type: 'BOOKING_CREATED' | 'BOOKING_CONFIRMED' | 'BOOKING_CANCELLED' | 'BOOKING_COMPLETED' | 'REVIEW_CREATED' | 'COMPLAINT_OPENED' | 'COMPLAINT_RESOLVED' | 'SYSTEM';
  @Column() title: string;
  @Column() message: string;
  @Column({ default: false }) read: boolean;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
}
