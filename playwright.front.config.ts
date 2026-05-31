import { defineConfig, devices } from '@playwright/test';

const WEB_DIR = 'mypet_app/build/web';
const WEB_PORT = 8080;

export default defineConfig({
  testDir: './services/tests/playwright-front',
  timeout: 180_000,
  expect: { timeout: 25_000 },
  retries: 1,
  workers: 1,
  reporter: [['list'], ['html', { open: 'never', outputFolder: 'services/tests/playwright-report-front' }]],
  outputDir: 'services/tests/test-results',
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
    command: `python -m http.server ${WEB_PORT} --directory ${WEB_DIR}`,
    url: `http://localhost:${WEB_PORT}/index.html`,
    reuseExistingServer: true,
    timeout: 30_000,
  },
});
