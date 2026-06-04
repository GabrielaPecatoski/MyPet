import { defineConfig, devices } from '@playwright/test';
import path from 'path';
const ROOT = path.resolve(__dirname, '../../..');
const WEB_DIR = path.join(ROOT, 'mypet_app/build/web');
const WEB_PORT = 8080;
export default defineConfig({
  testDir: __dirname,
  timeout: 180_000,
  expect: { timeout: 25_000 },
  retries: 1,
  workers: 1,
  reporter: [
    ['list'],
    ['html', { open: 'never', outputFolder: path.join(ROOT, 'services/tests/playwright-report-front') }],
  ],
  outputDir: path.join(ROOT, 'services/tests/test-results'),
  use: {
    baseURL: `http://localhost:${WEB_PORT}`,
    headless: false,
    viewport: { width: 1280, height: 900 },
    actionTimeout: 20_000,
    navigationTimeout: 30_000,
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    launchOptions: { slowMo: 120 },
  },
  projects: [
    { name: 'chromium-front', use: { ...devices['Desktop Chrome'], headless: false } },
  ],
  webServer: {
    command: `python -m http.server ${WEB_PORT} --directory "${WEB_DIR}"`,
    url: `http://localhost:${WEB_PORT}`,
    reuseExistingServer: true,
    timeout: 30_000,
  },
});
