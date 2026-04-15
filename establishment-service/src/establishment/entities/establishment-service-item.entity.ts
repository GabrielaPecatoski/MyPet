import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn } from 'typeorm';
import { Establishment } from './establishment.entity';

@Entity('establishment_services')
export class EstablishmentServiceItem {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'establishment_id' })
  establishmentId: string;

  @ManyToOne(() => Establishment, est => est.services, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'establishment_id' })
  establishment: Establishment;

  @Column()
  name: string;

  @Column({ type: 'decimal', precision: 10, scale: 2 })
  price: number;

  @Column({ name: 'duration_minutes', nullable: true })
  durationMinutes: number;
}
