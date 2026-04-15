import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('bookings')
export class Booking {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'pet_id', nullable: true }) petId: string;
  @Column({ name: 'pet_name', nullable: true }) petName: string;
  @Column({ name: 'service_name' }) serviceName: string;
  @Column({ name: 'establishment_id' }) establishmentId: string;
  @Column({ name: 'establishment_name', nullable: true }) establishmentName: string;
  @Column({ name: 'establishment_owner_id', nullable: true }) establishmentOwnerId: string;
  @Column({ name: 'scheduled_at' }) scheduledAt: string;
  @Column({ type: 'varchar', default: 'PENDENTE' })
  status: 'PENDENTE' | 'CONFIRMADO' | 'RECUSADO' | 'CANCELADO' | 'CONCLUIDO';
  @Column({ name: 'cancel_reason', nullable: true }) cancelReason: string;
  @Column({ nullable: true }) notes: string;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at' }) updatedAt: Date;
}
