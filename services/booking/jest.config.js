/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: "node",
  rootDir: ".",
  testMatch: ["<rootDir>/test/**/*.spec.ts"],
  modulePaths: ["<rootDir>/../../node_modules"],
  transform: {
    "^.+\\.ts$": [
      "ts-jest",
      { tsconfig: "<rootDir>/tsconfig.test.json", diagnostics: false },
    ],
  },
  moduleNameMapper: {
    "^@booking/(.*)$": "<rootDir>/src/modules/booking/$1",
    "^@shared/(.*)$": "<rootDir>/../../shared/src/$1",
  },
};
