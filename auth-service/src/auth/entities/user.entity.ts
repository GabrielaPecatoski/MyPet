import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn } from 'typeorm';

@Entity('users')
export class User {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  name: string;

  @Column({ unique: true })
  email: string;

  @Column({ name: 'password_hash' })
  passwordHash: string;

  @Column({ nullable: true })
  phone: string;

  @Column({ nullable: true })
  cpf: string;

  @Column({ type: 'varchar', default: 'CLIENTE' })
  role: 'ADMIN' | 'CLIENTE' | 'VENDEDOR';

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
