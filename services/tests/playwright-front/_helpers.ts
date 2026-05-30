import { Page, Locator, expect } from '@playwright/test';

export async function bootFlutter(page: Page, route = '/'): Promise<void> {
  await page.goto(route);
  await page.waitForSelector('flutter-view, flt-glass-pane, flt-scene-host', { timeout: 30_000 });
  await enableSemantics(page);
}

async function semanticsOn(page: Page): Promise<boolean> {
  return page.evaluate(() => document.querySelectorAll('flt-semantics').length > 0);
}

export async function enableSemantics(page: Page): Promise<void> {
  if (await semanticsOn(page)) return;
  for (let i = 0; i < 20; i++) {
    await page.evaluate(() => {
      const ph = document.querySelector(
        'flt-semantics-placeholder, [aria-label="Enable accessibility"]',
      ) as HTMLElement | null;
      ph?.click();
      ph?.dispatchEvent(new Event('click', { bubbles: true }));
    });
    if (await semanticsOn(page)) return;
    await page.waitForTimeout(400);
  }
  throw new Error('Nao foi possivel habilitar a arvore de semantics do Flutter.');
}

export function button(page: Page, name: string | RegExp, exact = false): Locator {
  return page.getByRole('button', { name, exact });
}

export function byText(page: Page, text: string | RegExp): Locator {
  if (typeof text === 'string') {
    const esc = JSON.stringify(text);
    return page.locator(`flt-semantics:has-text(${esc}), flt-semantics[aria-label*=${esc}]`);
  }
  return page.locator('flt-semantics').filter({ hasText: text });
}

export function leafByText(page: Page, text: string | RegExp): Locator {
  return page.locator('flt-semantics:not(:has(flt-semantics))').filter({ hasText: text });
}

export function textFields(page: Page): Locator {
  return page.locator('input[data-semantics-role="text-field"], textarea[data-semantics-role="text-field"]');
}

export function emailField(page: Page): Locator {
  return page.locator('input[autocomplete="email"], input[inputmode="email"]').first();
}

export function passwordField(page: Page): Locator {
  return page.locator('input[type="password"]').first();
}

export function fieldByHint(page: Page, hint: string | RegExp): Locator {
  const sel = typeof hint === 'string'
    ? `input[aria-label*=${JSON.stringify(hint)}], textarea[aria-label*=${JSON.stringify(hint)}]`
    : '';
  return sel ? page.locator(sel).first() : textFields(page).first();
}

export async function tapButton(page: Page, name: string | RegExp, exact = false): Promise<void> {
  const b = button(page, name, exact).first();
  await b.waitFor({ state: 'visible', timeout: 20_000 });
  await b.click();
}

export async function tapText(page: Page, text: string | RegExp): Promise<void> {
  const btn = page.getByRole('button', { name: text, exact: false });
  if (await btn.count()) {
    await btn.first().click({ timeout: 20_000 });
    return;
  }
  const el = leafByText(page, text).first();
  await el.scrollIntoViewIfNeeded().catch(() => {});
  await el.waitFor({ state: 'visible', timeout: 20_000 });
  await el.click({ force: true });
}

export async function fill(field: Locator, value: string): Promise<void> {
  await field.waitFor({ state: 'attached', timeout: 20_000 });
  for (let i = 0; i < 3; i++) {
    await field.click();
    await field.fill(value);
    try {
      if ((await field.inputValue()) === value) return;
    } catch {
      return;
    }
    await field.page().waitForTimeout(150);
  }
}

export async function fillNth(page: Page, index: number, value: string): Promise<void> {
  await fill(textFields(page).nth(index), value);
}

export async function waitForText(page: Page, text: string | RegExp, timeout = 30_000): Promise<void> {
  await byText(page, text).first().waitFor({ state: 'visible', timeout });
}

export async function expectText(page: Page, text: string | RegExp): Promise<void> {
  await expect(byText(page, text).first()).toBeVisible({ timeout: 30_000 });
}

export async function scrollToText(page: Page, text: string | RegExp, maxScrolls = 40): Promise<void> {
  await page.mouse.move(640, 450);
  await page.mouse.wheel(0, -8000);
  await page.waitForTimeout(400);
  for (let i = 0; i < maxScrolls; i++) {
    if (await byText(page, text).first().isVisible().catch(() => false)) return;
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(250);
  }
  await byText(page, text).first().waitFor({ state: 'visible', timeout: 10_000 });
}

export async function login(page: Page, email: string, senha: string): Promise<void> {
  await fill(emailField(page), email);
  await fill(passwordField(page), senha);
  await tapButton(page, 'Entrar');
}

export async function bootAndLogin(page: Page, email: string, senha: string): Promise<void> {
  await bootFlutter(page, '/');
  await waitForText(page, 'Entrar');
  await login(page, email, senha);
}

export async function dumpSemantics(page: Page): Promise<string> {
  return page.evaluate(() => {
    const host = document.querySelector('flt-semantics-host');
    if (!host) return 'NO HOST';
    const out: string[] = [];
    host.querySelectorAll('flt-semantics, input, textarea').forEach((n) => {
      const el = n as HTMLElement;
      const role = el.getAttribute('role');
      const aria = el.getAttribute('aria-label');
      const tag = el.tagName.toLowerCase();
      let txt = '';
      el.childNodes.forEach((c) => {
        if (c.nodeType === Node.TEXT_NODE) txt += c.textContent || '';
        if (c.nodeName.toLowerCase() === 'span') txt += (c.textContent || '');
      });
      txt = txt.trim();
      if (tag === 'input' || tag === 'textarea') {
        out.push(`${tag}[${el.getAttribute('type') || 'text'}]${aria ? ` aria="${aria}"` : ''}`);
      } else if (role || txt) {
        out.push(`${tag}${role ? `[${role}]` : ''}${txt ? ` "${txt}"` : ''}`);
      }
    });
    return out.join('\n');
  });
}
