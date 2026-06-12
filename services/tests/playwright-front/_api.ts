import { APIRequestContext, request } from '@playwright/test';

export const API_BASE = 'http://localhost';

export interface SeededUser {
  id: string;
  name: string;
  email: string;
  password: string;
  token: string;
  role: string;
}

export async function apiContext(): Promise<APIRequestContext> {
  return request.newContext({ baseURL: API_BASE });
}

function auth(u: SeededUser) {
  return { Authorization: `Bearer ${u.token}` };
}

let counter = 0;
function unique(prefix: string): { email: string; cpf: string } {
  const ts = Date.now() + counter++;
  return {
    email: `${prefix}${ts}@mypet.com`,
    cpf: String(ts).slice(-11).padStart(11, '0'),
  };
}

async function ok(res: Awaited<ReturnType<APIRequestContext['post']>>, ctx: string) {
  if (!res.ok()) throw new Error(`${ctx} falhou ${res.status()}: ${await res.text()}`);
  const txt = await res.text();
  return txt ? JSON.parse(txt) : {};
}

export async function registerUser(
  api: APIRequestContext,
  opts: { role?: 'CLIENTE' | 'VENDEDOR'; password?: string; businessName?: string; namePrefix?: string } = {},
): Promise<SeededUser> {
  const { email, cpf } = unique(opts.role === 'VENDEDOR' ? 'estab' : 'cli');
  const password = opts.password ?? 'senha123';
  const body = await ok(
    await api.post('/auth/register', {
      data: {
        name: opts.namePrefix ?? (opts.role === 'VENDEDOR' ? 'Estab E2E' : 'Cliente E2E'),
        email,
        password,
        phone: '41999990000',
        cpf,
        role: opts.role ?? 'CLIENTE',
        businessName: opts.businessName,
      },
    }),
    'registerUser',
  );
  return { id: body.user.id, name: body.user.name, email, password, token: body.accessToken, role: body.user.role };
}

export async function createEstablishment(
  api: APIRequestContext,
  owner: SeededUser,
  data: Partial<{ name: string; type: string; address: string; city: string; phone: string }> = {},
): Promise<any> {
  return ok(
    await api.post(`/establishments/owner/${owner.id}`, {
      headers: auth(owner),
      data: {
        name: data.name ?? `Pet Shop E2E ${Date.now()}`,
        description: 'Estabelecimento pet E2E',
        address: data.address ?? 'Rua dos Testes, 100',
        city: data.city ?? 'Curitiba',
        phone: data.phone ?? '4133334444',
        type: data.type ?? 'PET_SHOP',
      },
    }),
    'createEstablishment',
  );
}

export async function addService(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
  data: Partial<{ name: string; price: number; durationMinutes: number; description: string }> = {},
): Promise<any> {
  return ok(
    await api.post(`/establishments/${establishmentId}/services`, {
      headers: auth(owner),
      data: {
        name: data.name ?? 'Banho E2E',
        price: data.price ?? 80,
        durationMinutes: data.durationMinutes ?? 60,
        description: data.description ?? 'Banho completo',
      },
    }),
    'addService',
  );
}

export async function setSchedule(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
): Promise<any> {
  const days = Array.from({ length: 7 }, (_, dayOfWeek) => ({
    dayOfWeek,
    startTime: '08:00',
    endTime: '20:00',
    isOpen: true,
  }));
  return ok(
    await api.post('/availability/schedule', {
      headers: auth(owner),
      data: { establishmentId, slotDurationMinutes: 60, capacity: 5, days },
    }),
    'setSchedule',
  );
}

export async function createProduct(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
  data: Partial<{ name: string; brand: string; price: number; stock: number; category: string }> = {},
): Promise<any> {
  return ok(
    await api.post('/marketplace/products', {
      headers: auth(owner),
      data: {
        name: data.name ?? `Racao E2E ${Date.now()}`,
        brand: data.brand ?? 'Marca E2E',
        price: data.price ?? 49.9,
        stock: data.stock ?? 25,
        category: data.category ?? 'Alimentacao',
        establishmentId,
      },
    }),
    'createProduct',
  );
}

export async function createPet(
  api: APIRequestContext,
  owner: SeededUser,
  data: Partial<{ name: string; type: string; breed: string; age: number }> = {},
): Promise<any> {
  return ok(
    await api.post(`/pets/user/${owner.id}`, {
      headers: auth(owner),
      data: {
        name: data.name ?? 'Rex E2E',
        type: data.type ?? 'Cachorro',
        breed: data.breed ?? 'Labrador',
        age: data.age ?? 3,
      },
    }),
    'createPet',
  );
}

export async function createBooking(
  api: APIRequestContext,
  cliente: SeededUser,
  args: {
    petId: string; petName: string; serviceName: string;
    establishmentId: string; establishmentName: string; price: number; scheduledAt: Date;
  },
): Promise<any> {
  return ok(
    await api.post('/bookings', {
      headers: auth(cliente),
      data: {
        userName: cliente.name,
        petId: args.petId,
        petName: args.petName,
        serviceName: args.serviceName,
        establishmentId: args.establishmentId,
        establishmentName: args.establishmentName,
        scheduledAt: args.scheduledAt.toISOString(),
        price: args.price,
      },
    }),
    'createBooking',
  );
}

export async function payBooking(
  api: APIRequestContext,
  cliente: SeededUser,
  bookingId: string,
): Promise<any> {
  return ok(
    await api.patch(`/bookings/${bookingId}/pay`, {
      headers: auth(cliente),
      data: { method: 'PIX' },
    }),
    'payBooking',
  );
}

export async function seedFullEstablishment(api: APIRequestContext, serviceName = 'Banho E2E') {
  const owner = await registerUser(api, { role: 'VENDEDOR', businessName: 'Estab E2E' });
  const estab = await createEstablishment(api, owner, { name: `Pet Shop E2E ${Date.now()}` });
  const service = await addService(api, owner, estab.id, { name: serviceName });
  await setSchedule(api, owner, estab.id);
  const product = await createProduct(api, owner, estab.id, { name: `Racao E2E ${Date.now()}` });
  return { owner, estab, service, product };
}
