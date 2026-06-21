/**
 * Global setup: cria usuários de teste e salva credenciais/tokens
 * em variáveis de ambiente para uso nos specs.
 */

import fs from 'fs';
import path from 'path';
import { loginOrRegister, getOrCreateEstablishment, type LoginResult } from './utils/api';

export interface TestCredentials {
  client: LoginResult;
  vendor: LoginResult;
  admin: LoginResult;
  establishmentId: string;
}

const CREDS_FILE = path.join(__dirname, '.auth', 'credentials.json');

async function setup(): Promise<void> {
  console.log('\n[E2E] Preparando usuários de teste...\n');

  // Garante que a pasta .auth existe
  fs.mkdirSync(path.dirname(CREDS_FILE), { recursive: true });

  // ── Cliente de teste
  const client = await loginOrRegister({
    name: 'Cliente E2E',
    email: 'e2e.client@mypet.test',
    password: 'Senha@123',
    phone: '(11) 91111-1111',
    cpf: '999.888.777-01',
    role: 'CLIENTE',
  });
  console.log(`  ✓ Cliente: ${client.user.email}`);

  // ── Vendedor de teste
  const vendor = await loginOrRegister({
    name: 'Vendedor E2E',
    email: 'e2e.vendor@mypet.test',
    password: 'Senha@123',
    phone: '(11) 92222-2222',
    cpf: '999.888.777-02',
    role: 'VENDEDOR',
    businessName: 'Pet Shop E2E',
  });
  console.log(`  ✓ Vendedor: ${vendor.user.email}`);

  // Garante que o vendedor tem um estabelecimento
  const estab = await getOrCreateEstablishment(vendor.accessToken, {
    name: 'Pet Shop E2E',
    description: 'Estabelecimento criado para testes automatizados',
    address: 'Rua de Teste, 999',
    city: 'São Paulo',
    phone: '(11) 3000-9999',
    type: 'PET_SHOP',
  });
  console.log(`  ✓ Estabelecimento: ${estab.name} (id: ${estab.id})`);

  // ── Admin (usa conta do seed; se não existir tenta criar)
  const adminEmail = process.env.ADMIN_EMAIL ?? 'admin@mypet.com';
  const adminPassword = process.env.ADMIN_PASSWORD ?? 'admin123';
  const admin = await loginOrRegister({
    name: 'Administrador',
    email: adminEmail,
    password: adminPassword,
    phone: '(11) 99999-0001',
    cpf: '000.000.000-01',
    role: 'ADMIN',
  });
  console.log(`  ✓ Admin: ${admin.user.email}`);

  const credentials: TestCredentials = {
    client,
    vendor,
    admin,
    establishmentId: estab.id,
  };

  fs.writeFileSync(CREDS_FILE, JSON.stringify(credentials, null, 2));
  console.log(`\n[E2E] Credenciais salvas em ${CREDS_FILE}\n`);
}

export default setup;
