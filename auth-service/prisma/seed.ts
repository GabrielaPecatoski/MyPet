import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const users = [
    {
      id: 'admin-001',
      name: 'Admin MyPet',
      email: 'admin@mypet.com',
      password: 'admin123',
      phone: '(11) 99999-0001',
      cpf: '000.000.000-00',
      role: 'ADMIN' as const,
    },
    {
      id: 'cliente-001',
      name: 'João Silva',
      email: 'joao@mypet.com',
      password: 'cliente123',
      phone: '(11) 99999-9999',
      cpf: '123.456.789-00',
      role: 'CLIENTE' as const,
    },
    {
      id: 'vendedor-001',
      name: 'Pet Shop Amor & Carinho',
      email: 'petshop@mypet.com',
      password: 'vendedor123',
      phone: '(11) 3456-7890',
      cpf: '99.999.999/0001-99',
      role: 'VENDEDOR' as const,
    },
  ];

  for (const u of users) {
    const hashed = await bcrypt.hash(u.password, 10);
    await prisma.user.upsert({
      where: { email: u.email },
      update: {},
      create: { ...u, password: hashed },
    });
    console.log(`✓ ${u.role}: ${u.email}`);
  }
}

main()
  .catch(console.error)
  .finally(() => prisma.$disconnect());
