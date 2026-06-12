import { APIRequestContext, expect, test } from "@playwright/test";
import { apiContext, registerUser, registerVet, SeededUser } from "./_api";
import { bootAndLogin, tapButton, waitForText } from "./_helpers";

let api: APIRequestContext;
let vetUser: SeededUser;
let vet: any;

test.beforeAll(async () => {
  api = await apiContext();
  vetUser = await registerUser(api, {
    role: "VETERINARIO",
    namePrefix: "Vet Alarme E2E",
  });
  vet = await registerVet(api, vetUser, { especialidade: "Emergencista" });
  const res = await api.patch(`/veterinarians/${vet.id}/availability`, {
    headers: { Authorization: `Bearer ${vetUser.token}` },
    data: { atende24h: true },
  });
  expect(res.ok()).toBe(true);
});

test.afterAll(async () => {
  await api.dispose();
});

test("chamado de emergência dispara o alarme em tempo real (SSE)", async ({
  page,
}) => {
  await bootAndLogin(page, vetUser.email, vetUser.password);
  await waitForText(page, "MY PET · VETERINÁRIO");
  await waitForText(page, "Atender emergências 24h");

  await page.waitForTimeout(3000);

  const fired = Date.now();
  const res = await api.post(`/veterinarians/${vet.id}/emergency-call`, {
    headers: { Authorization: `Bearer ${vetUser.token}` },
    data: {
      callerName: "Tutor Alarme E2E",
      callerPhone: "41977770001",
      petDescription: "Gato engasgado",
    },
  });
  expect(res.ok()).toBe(true);

  await waitForText(page, "EMERGÊNCIA!", 10_000);
  const elapsed = (Date.now() - fired) / 1000;
  console.log(`overlay do alarme em ${elapsed.toFixed(1)}s`);
  await waitForText(page, "Tutor Alarme E2E");

  await tapButton(page, "Recusar");
  await expect
    .poll(
      async () => {
        const r = await api.get(
          `/veterinarians/${vet.id}/emergency-calls/pending`,
          { headers: { Authorization: `Bearer ${vetUser.token}` } },
        );
        return ((await r.json()) as unknown[]).length;
      },
      { timeout: 10_000 },
    )
    .toBe(0);
});
