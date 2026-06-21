/** @type {import('jest').Config} */
module.exports = {
  testEnvironment: "node",
  forceExit: true,
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
    "^@notification/(.*)$": "<rootDir>/src/modules/notification/$1",
    "^@shared/(.*)$": "<rootDir>/../../shared/src/$1",
  },
};
