import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './services/tests/playwright-tests',
  timeout: 30_000,
  retries: 0,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    baseURL: 'http://localhost:3004',
    extraHTTPHeaders: { 'Content-Type': 'application/json' },
  },
});
