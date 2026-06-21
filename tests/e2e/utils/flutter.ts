/**
 * Helpers para interagir com Flutter Web via Playwright.
 *
 * Flutter Web expõe a árvore de acessibilidade via <flt-semantics>.
 * Compatível com HTML renderer e CanvasKit renderer.
 *
 * Para melhor compatibilidade, inicie com HTML renderer:
 *   flutter run -d web-server --web-port 8080 --web-renderer html
 */

import { expect, type Page } from '@playwright/test';

// ────────────────────────────────────────────────────────────────────────────
// HELPERS DE ESPERA
// ────────────────────────────────────────────────────────────────────────────

/** Aguarda o Flutter montar a árvore semântica no DOM. */
export async function waitForFlutter(page: Page): Promise<void> {
  await page.waitForSelector('flt-glass-pane', { timeout: 45_000 });
  await page.waitForLoadState('networkidle', { timeout: 30_000 });
  await page.waitForSelector('flt-semantics', { timeout: 30_000 });
}

/** Aguarda a splash screen terminar e a primeira tela real aparecer. */
export async function waitForSplash(page: Page): Promise<void> {
  await waitForFlutter(page);
  await page.waitForTimeout(2_000);
  await page.waitForLoadState('networkidle');
}

/**
 * Aguarda um texto aparecer na tela.
 * Funciona com HTML renderer (body.innerText) e CanvasKit (flt-semantics aria-label).
 * Aceita string literal ou RegExp.
 */
export async function waitForText(
  page: Page,
  text: string | RegExp,
  timeout = 15_000,
): Promise<void> {
  if (text instanceof RegExp) {
    // Para RegExp serializa para string e reconstrói no browser
    const src = text.source;
    const flags = text.flags;
    await page.waitForFunction(
      ({ src, flags }: { src: string; flags: string }) => {
        const re = new RegExp(src, flags);
        // Tenta body.innerText (HTML renderer)
        if (re.test(document.body.innerText)) return true;
        // Tenta flt-semantics (CanvasKit accessibility tree)
        for (const el of document.querySelectorAll('flt-semantics')) {
          const label = el.getAttribute('aria-label') ?? '';
          const content = el.textContent ?? '';
          if (re.test(label) || re.test(content)) return true;
        }
        return false;
      },
      { src, flags },
      { timeout },
    );
  } else {
    await page.waitForFunction(
      (t: string) => {
        if (document.body.innerText.includes(t)) return true;
        for (const el of document.querySelectorAll('flt-semantics')) {
          const label = el.getAttribute('aria-label') ?? '';
          const content = el.textContent ?? '';
          if (label.includes(t) || content.includes(t)) return true;
        }
        return false;
      },
      text,
      { timeout },
    );
  }
}

/**
 * Aguarda um snackbar aparecer com determinado texto.
 */
export async function waitForSnackbar(
  page: Page,
  text: string | RegExp,
  timeout = 8_000,
): Promise<void> {
  await waitForText(page, text, timeout);
}

// ────────────────────────────────────────────────────────────────────────────
// HELPERS DE INTERAÇÃO
// ────────────────────────────────────────────────────────────────────────────

/**
 * Preenche um campo de texto Flutter pela posição (0-indexed).
 *
 * Flutter cria um <input> real quando o campo semântico é focado.
 * Este helper: clica no campo → aguarda o input aparecer → preenche.
 */
export async function fillField(
  page: Page,
  index: number,
  value: string,
): Promise<void> {
  const fields = page.locator('[role="textbox"]');
  const field = fields.nth(index);
  await field.waitFor({ state: 'visible', timeout: 10_000 });
  await field.click();
  await page.waitForTimeout(300);

  // Tenta preencher via input real criado pelo Flutter (HTML renderer)
  const activeInput = page.locator(
    'input.flt-text-editing-input, textarea.flt-text-editing-input, ' +
      'input[data-semantics-role="text-field"], input:focus',
  );

  if ((await activeInput.count()) > 0) {
    await activeInput.first().fill(value);
  } else {
    // Fallback: digita via teclado (funciona com CanvasKit)
    await page.keyboard.press('Control+A');
    await page.keyboard.type(value, { delay: 30 });
  }
}

/**
 * Limpa um campo e preenche com novo valor.
 */
export async function clearAndFillField(
  page: Page,
  index: number,
  value: string,
): Promise<void> {
  const fields = page.locator('[role="textbox"]');
  await fields.nth(index).click();
  await page.waitForTimeout(200);
  await page.keyboard.press('Control+A');
  await page.keyboard.press('Delete');
  await page.waitForTimeout(100);
  await page.keyboard.type(value, { delay: 30 });
}

/**
 * Clica em um botão Flutter pelo texto visível (role="button").
 */
export async function clickButton(page: Page, text: string): Promise<void> {
  const btn = page
    .locator('[role="button"]')
    .filter({ hasText: text })
    .first();
  await btn.waitFor({ state: 'visible', timeout: 10_000 });
  await btn.click();
}

/**
 * Verifica que um texto está visível na tela (via accessibility tree).
 */
export async function expectVisible(page: Page, text: string): Promise<void> {
  await expect(
    page
      .locator('flt-semantics')
      .filter({ hasText: text })
      .first(),
  ).toBeVisible({ timeout: 15_000 });
}

// ────────────────────────────────────────────────────────────────────────────
// HELPERS DE AUTENTICAÇÃO
// ────────────────────────────────────────────────────────────────────────────

/**
 * Injeta token + usuário no localStorage antes de navegar.
 * Simula login já realizado, evitando passar pela UI de login.
 *
 * Flutter SharedPreferences na web usa prefixo "flutter.":
 *   flutter.auth_token  → JWT
 *   flutter.auth_user   → JSON do usuário
 */
export async function injectAuthState(
  page: Page,
  token: string,
  user: Record<string, unknown>,
): Promise<void> {
  await page.addInitScript(
    ({ token, user }: { token: string; user: Record<string, unknown> }) => {
      localStorage.setItem('flutter.auth_token', token);
      localStorage.setItem('flutter.auth_user', JSON.stringify(user));
    },
    { token, user },
  );
}

/**
 * Remove o estado de autenticação do localStorage.
 */
export async function clearAuthState(page: Page): Promise<void> {
  await page.evaluate(() => {
    localStorage.removeItem('flutter.auth_token');
    localStorage.removeItem('flutter.auth_user');
  });
}

// ────────────────────────────────────────────────────────────────────────────
// HELPERS DE NAVEGAÇÃO
// ────────────────────────────────────────────────────────────────────────────

/**
 * Clica em uma aba do bottom navigation pelo índice.
 * Tenta role="tab" primeiro, depois role="button" como fallback.
 */
export async function tapBottomNav(page: Page, index: number): Promise<void> {
  const tabs = page.locator('[role="tab"]');
  if ((await tabs.count()) > index) {
    await tabs.nth(index).click();
    return;
  }
  // Fallback: navega pelos botões (Flutter pode não usar role="tab")
  const btns = page.locator('[role="button"]');
  const total = await btns.count();
  if (total > index) {
    await btns.nth(total - 5 + index).click();
  }
}

/**
 * Verifica a URL atual do Flutter (funciona com hash routing).
 */
export async function expectRoute(page: Page, route: string): Promise<void> {
  await expect(page).toHaveURL(new RegExp(route.replace(/\//g, '\\/')), {
    timeout: 15_000,
  });
}
