import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn } from 'typeorm';

@Entity('complaints')
export class Complaint {
  @PrimaryGeneratedColumn('uuid') id: string;
  @Column({ name: 'user_id' }) userId: string;
  @Column({ name: 'user_name', nullable: true }) userName: string;
  @Column({ name: 'establishment_id' }) establishmentId: string;
  @Column({ name: 'booking_id', nullable: true }) bookingId: string;
  @Column() title: string;
  @Column({ type: 'text' }) description: string;
  @Column({ type: 'varchar', default: 'PENDENTE' })
  status: 'PENDENTE' | 'RESPONDIDA' | 'ARQUIVADA' | 'REMOVIDA';
  @Column({ type: 'text', nullable: true }) response: string;
  @Column({ name: 'moderator_note', nullable: true }) moderatorNote: string;
  @CreateDateColumn({ name: 'created_at' }) createdAt: Date;
  @UpdateDateColumn({ name: 'updated_at' }) updatedAt: Date;
}
