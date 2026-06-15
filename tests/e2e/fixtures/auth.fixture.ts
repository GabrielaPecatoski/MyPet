/**
 * Fixture de autenticação: injeta token no localStorage antes de cada teste,
 * evitando passar pelo fluxo de login via UI a cada spec.
 */

import fs from 'fs';
import path from 'path';
import { test as base, type Page } from '@playwright/test';
import { injectAuthState } from '../utils/flutter';
import type { TestCredentials } from '../global-setup';

const CREDS_FILE = path.join(__dirname, '..', '.auth', 'credentials.json');

function loadCredentials(): TestCredentials {
  if (!fs.existsSync(CREDS_FILE)) {
    throw new Error(
      `Arquivo de credenciais não encontrado: ${CREDS_FILE}\n` +
        'Execute o global-setup antes de rodar os testes.',
    );
  }
  return JSON.parse(fs.readFileSync(CREDS_FILE, 'utf-8')) as TestCredentials;
}

interface AuthFixtures {
  clientPage: Page;
  vendorPage: Page;
  adminPage: Page;
  establishmentId: string;
  credentials: TestCredentials;
}

export const test = base.extend<AuthFixtures>({
  credentials: async ({}, use) => {
    await use(loadCredentials());
  },

  establishmentId: async ({}, use) => {
    const creds = loadCredentials();
    await use(creds.establishmentId);
  },

  // Página pré-autenticada como CLIENTE
  clientPage: async ({ page }, use) => {
    const creds = loadCredentials();
    await injectAuthState(page, creds.client.accessToken, creds.client.user);
    await use(page);
  },

  // Página pré-autenticada como VENDEDOR
  vendorPage: async ({ page }, use) => {
    const creds = loadCredentials();
    await injectAuthState(page, creds.vendor.accessToken, creds.vendor.user);
    await use(page);
  },

  // Página pré-autenticada como ADMIN
  adminPage: async ({ page }, use) => {
    const creds = loadCredentials();
    await injectAuthState(page, creds.admin.accessToken, creds.admin.user);
    await use(page);
  },
});

export { expect } from '@playwright/test';
