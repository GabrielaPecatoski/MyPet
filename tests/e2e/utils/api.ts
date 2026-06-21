/**
 * HTTP client para chamadas diretas ao backend durante setup/teardown dos testes.
 */

export const API_BASE = process.env.API_URL ?? 'http://localhost:3000';

export interface LoginResult {
  accessToken: string;
  user: {
    id: string;
    name: string;
    email: string;
    role: string;
    phone: string;
    cpf: string;
  };
}

async function request<T>(
  method: string,
  path: string,
  body?: unknown,
  token?: string,
): Promise<T> {
  const headers: Record<string, string> = { 'Content-Type': 'application/json' };
  if (token) headers.Authorization = `Bearer ${token}`;

  const res = await fetch(`${API_BASE}${path}`, {
    method,
    headers,
    body: body ? JSON.stringify(body) : undefined,
  });

  const text = await res.text();
  let data: unknown;
  try {
    data = JSON.parse(text);
  } catch {
    data = text;
  }

  if (!res.ok) {
    throw new Error(`[${method} ${path}] ${res.status}: ${text}`);
  }
  return data as T;
}

export const api = {
  post: <T>(path: string, body: unknown, token?: string) =>
    request<T>('POST', path, body, token),
  get: <T>(path: string, token?: string) =>
    request<T>('GET', path, undefined, token),
  put: <T>(path: string, body: unknown, token?: string) =>
    request<T>('PUT', path, body, token),
  patch: <T>(path: string, body: unknown, token?: string) =>
    request<T>('PATCH', path, body, token),
  delete: <T>(path: string, token?: string) =>
    request<T>('DELETE', path, undefined, token),
};

export async function loginOrRegister(params: {
  name: string;
  email: string;
  password: string;
  phone: string;
  cpf: string;
  role: 'CLIENTE' | 'VENDEDOR' | 'ADMIN';
  businessName?: string;
}): Promise<LoginResult> {
  // Tenta login primeiro
  try {
    const result = await api.post<LoginResult>('/auth/login', {
      email: params.email,
      password: params.password,
    });
    return result;
  } catch {
    // Se falhou (usuário não existe), registra
  }

  try {
    const result = await api.post<LoginResult>('/auth/register', params);
    return result;
  } catch (err) {
    throw new Error(`Falha ao criar/logar usuário ${params.email}: ${err}`);
  }
}

export async function getOrCreateEstablishment(
  token: string,
  establishment: {
    name: string;
    description: string;
    address: string;
    city: string;
    phone: string;
    type: string;
  },
): Promise<{ id: string; name: string }> {
  const existing = await api.get<{ id: string; name: string }[]>('/establishments', token);
  const found = existing.find((e) => e.name === establishment.name);
  if (found) return found;

  return api.post<{ id: string; name: string }>('/establishments', establishment, token);
}
