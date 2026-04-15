import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany } from 'typeorm';
import { EstablishmentServiceItem } from './establishment-service-item.entity';

@Entity('establishments')
export class Establishment {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'owner_id' })
  ownerId: string;

  @Column()
  name: string;

  @Column({ nullable: true })
  description: string;

  @Column({ nullable: true })
  address: string;

  @Column({ nullable: true })
  city: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ name: 'image_url', nullable: true })
  imageUrl: string;

  @OneToMany(() => EstablishmentServiceItem, s => s.establishment, { cascade: true, eager: true })
  services: EstablishmentServiceItem[];

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
