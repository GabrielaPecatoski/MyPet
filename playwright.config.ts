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
    baseURL: "http://localhost:3004",
    extraHTTPHeaders: { "Content-Type": "application/json" },
  },
});
