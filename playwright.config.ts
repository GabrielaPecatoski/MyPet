import { defineConfig } from "@playwright/test";

export default defineConfig({
  testDir: "./services/tests/playwright-tests",
  timeout: 30_000,
  retries: 0,
  reporter: [
    ["list"],
    [
      "html",
      { open: "never", outputFolder: "services/tests/playwright-report" },
    ],
  ],
  outputDir: "services/tests/test-results",
  use: {
    // backend real via Nginx (mesmo gateway que o app usa)
    baseURL: process.env.API_BASE ?? "http://127.0.0.1",
    extraHTTPHeaders: { "Content-Type": "application/json" },
  },
});
