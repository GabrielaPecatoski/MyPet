import { APIRequestContext, request } from "@playwright/test";
export const API_BASE = "http://127.0.0.1";
export interface SeededUser {
  id: string;
  name: string;
  email: string;
  password: string;
  token: string;
  role: string;
  cpf: string;
}
export async function apiContext(): Promise<APIRequestContext> {
  return request.newContext({ baseURL: API_BASE, timeout: 60_000 });
}
function auth(u: SeededUser) {
  return { Authorization: `Bearer ${u.token}` };
}
let counter = 0;
function unique(prefix: string): { email: string; cpf: string } {
  const ts = Date.now() + counter++;
  return {
    email: `${prefix}${ts}@mypet.com`,
    cpf: String(ts).slice(-11).padStart(11, "0"),
  };
}
async function ok(
  res: Awaited<ReturnType<APIRequestContext["post"]>>,
  ctx: string,
) {
  if (!res.ok())
    throw new Error(`${ctx} falhou ${res.status()}: ${await res.text()}`);
  const txt = await res.text();
  return txt ? JSON.parse(txt) : {};
}
export async function registerUser(
  api: APIRequestContext,
  opts: {
    role?: "CLIENTE" | "VENDEDOR" | "MOTORISTA" | "VETERINARIO";
    password?: string;
    businessName?: string;
    namePrefix?: string;
  } = {},
): Promise<SeededUser> {
  const prefix =
    opts.role === "VENDEDOR"
      ? "estab"
      : opts.role === "MOTORISTA"
        ? "mot"
        : opts.role === "VETERINARIO"
          ? "vet"
          : "cli";
  const { email, cpf } = unique(prefix);
  const password = opts.password ?? "senha123";
  const body = await ok(
    await api.post("/auth/register", {
      data: {
        name:
          opts.namePrefix ??
          (opts.role === "VENDEDOR"
            ? "Estab E2E"
            : opts.role === "MOTORISTA"
              ? "Motorista E2E"
              : opts.role === "VETERINARIO"
                ? "Vet E2E"
                : "Cliente E2E"),
        email,
        password,
        phone: "41999990000",
        cpf,
        role: opts.role ?? "CLIENTE",
        businessName: opts.businessName,
      },
    }),
    "registerUser",
  );
  return {
    id: body.user.id,
    name: body.user.name,
    email,
    password,
    token: body.accessToken,
    role: body.user.role,
    cpf,
  };
}
export async function createEstablishment(
  api: APIRequestContext,
  owner: SeededUser,
  data: Partial<{
    name: string;
    type: string;
    address: string;
    city: string;
    phone: string;
  }> = {},
): Promise<any> {
  return ok(
    await api.post(`/establishments/owner/${owner.id}`, {
      headers: auth(owner),
      data: {
        name: data.name ?? `Pet Shop E2E ${Date.now()}`,
        description: "Estabelecimento pet E2E",
        address: data.address ?? "Rua dos Testes, 100",
        city: data.city ?? "Curitiba",
        phone: data.phone ?? "4133334444",
        type: data.type ?? "PET_SHOP",
      },
    }),
    "createEstablishment",
  );
}
export async function addService(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
  data: Partial<{
    name: string;
    price: number;
    durationMinutes: number;
    description: string;
  }> = {},
): Promise<any> {
  const payload = {
    name: data.name ?? "Banho E2E",
    price: data.price ?? 80,
    durationMinutes: data.durationMinutes ?? 60,
    description: data.description ?? "Banho completo",
  };
  await ok(
    await api.post(`/establishments/${establishmentId}/services`, {
      headers: auth(owner),
      data: payload,
    }),
    "addService",
  );
  const list = await ok(
    await api.get(`/establishments/${establishmentId}/services`, {
      headers: auth(owner),
    }),
    "addService:list",
  );
  return (
    (Array.isArray(list) ? list : []).find(
      (s: any) => s.name === payload.name,
    ) ?? payload
  );
}
export async function setSchedule(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
): Promise<any> {
  const days = Array.from({ length: 7 }, (_, dayOfWeek) => ({
    dayOfWeek,
    startTime: "08:00",
    endTime: "20:00",
    isOpen: true,
  }));
  return ok(
    await api.post("/availability/schedule", {
      headers: auth(owner),
      data: { establishmentId, slotDurationMinutes: 60, capacity: 5, days },
    }),
    "setSchedule",
  );
}
export async function createProduct(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
  data: Partial<{
    name: string;
    brand: string;
    price: number;
    stock: number;
    category: string;
  }> = {},
): Promise<any> {
  return ok(
    await api.post("/marketplace/products", {
      headers: auth(owner),
      data: {
        name: data.name ?? `Racao E2E ${Date.now()}`,
        brand: data.brand ?? "Marca E2E",
        price: data.price ?? 49.9,
        stock: data.stock ?? 25,
        category: data.category ?? "Alimentacao",
        establishmentId,
      },
    }),
    "createProduct",
  );
}
export async function createPet(
  api: APIRequestContext,
  owner: SeededUser,
  data: Partial<{
    name: string;
    type: string;
    breed: string;
    age: number;
  }> = {},
): Promise<any> {
  return ok(
    await api.post(`/pets/user/${owner.id}`, {
      headers: auth(owner),
      data: {
        name: data.name ?? "Rex E2E",
        type: data.type ?? "Cachorro",
        breed: data.breed ?? "Labrador",
        age: data.age ?? 3,
      },
    }),
    "createPet",
  );
}
export async function createBooking(
  api: APIRequestContext,
  cliente: SeededUser,
  args: {
    petId: string;
    petName: string;
    serviceName: string;
    establishmentId: string;
    establishmentName: string;
    price: number;
    scheduledAt: Date;
    driverId?: string;
    driverName?: string;
    driverPhotoUrl?: string;
  },
): Promise<any> {
  return ok(
    await api.post("/bookings", {
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
        driverId: args.driverId,
        driverName: args.driverName,
        driverPhotoUrl: args.driverPhotoUrl,
      },
    }),
    "createBooking",
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
      data: { method: "PIX" },
    }),
    "payBooking",
  );
}
export async function updateBookingStatus(
  api: APIRequestContext,
  actor: SeededUser,
  bookingId: string,
  status: "CONFIRMADO" | "RECUSADO" | "CONCLUIDO" | "CANCELADO",
): Promise<any> {
  return ok(
    await api.patch(`/bookings/${bookingId}/status`, {
      headers: auth(actor),
      data: { status },
    }),
    "updateBookingStatus",
  );
}
export async function setAttendancePhotos(
  api: APIRequestContext,
  actor: SeededUser,
  bookingId: string,
  photos: string[],
): Promise<any> {
  return ok(
    await api.patch(`/bookings/${bookingId}/photos`, {
      headers: auth(actor),
      data: { photos },
    }),
    "setAttendancePhotos",
  );
}
export async function getBooking(
  api: APIRequestContext,
  user: SeededUser,
  bookingId: string,
): Promise<any> {
  return ok(
    await api.get(`/bookings/${bookingId}`, { headers: auth(user) }),
    "getBooking",
  );
}
export async function listEstablishmentBookings(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
): Promise<any[]> {
  return ok(
    await api.get(`/bookings/establishment/${establishmentId}`, {
      headers: auth(owner),
    }),
    "listEstablishmentBookings",
  );
}
export async function listDriverTransports(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
): Promise<any[]> {
  const rows = await listEstablishmentBookings(api, owner, establishmentId);
  return rows.filter((b) => b.status === "CONFIRMADO");
}
export async function getEstablishmentReviews(
  api: APIRequestContext,
  establishmentId: string,
): Promise<any[]> {
  return ok(
    await api.get(`/reviews/establishment/${establishmentId}`),
    "getEstablishmentReviews",
  );
}
export async function addToCart(
  api: APIRequestContext,
  cliente: SeededUser,
  productId: string,
  quantity = 1,
): Promise<any> {
  return ok(
    await api.post(`/marketplace/cart/${cliente.id}`, {
      headers: auth(cliente),
      data: { productId, quantity },
    }),
    "addToCart",
  );
}
export async function checkoutOrder(
  api: APIRequestContext,
  cliente: SeededUser,
): Promise<any> {
  return ok(
    await api.post(`/marketplace/orders/${cliente.id}`, {
      headers: auth(cliente),
      data: {},
    }),
    "checkoutOrder",
  );
}
export async function payOrder(
  api: APIRequestContext,
  cliente: SeededUser,
  orderId: string,
  opts: {
    method?: string;
    deliveryMethod?: string;
    deliveryAddress?: string;
  } = {},
): Promise<any> {
  return ok(
    await api.post("/marketplace/payments", {
      headers: auth(cliente),
      data: {
        orderId,
        method: opts.method ?? "PIX",
        deliveryMethod: opts.deliveryMethod ?? "DELIVERY",
        deliveryAddress: opts.deliveryAddress ?? "Rua dos Testes, 100",
      },
    }),
    "payOrder",
  );
}
export async function seedPaidOrder(
  api: APIRequestContext,
  owner: SeededUser,
  estabId: string,
) {
  const product = await createProduct(api, owner, estabId, {
    name: `Pedido E2E ${Date.now()}`,
  });
  const cliente = await registerUser(api, { role: "CLIENTE" });
  await addToCart(api, cliente, product.id, 2);
  const order = await checkoutOrder(api, cliente);
  await payOrder(api, cliente, order.id, {
    method: "PIX",
    deliveryMethod: "DELIVERY",
  });
  return { cliente, product, orderId: order.id };
}
export async function addVariableService(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
  data: { name: string; durationMinutes?: number; description?: string } = {
    name: "Consulta E2E",
  },
): Promise<any> {
  const payload = {
    name: data.name,
    priceVariable: true,
    durationMinutes: data.durationMinutes ?? 60,
    description: data.description ?? "Consulta com preço variável",
  };
  await ok(
    await api.post(`/establishments/${establishmentId}/services`, {
      headers: { Authorization: `Bearer ${owner.token}` },
      data: payload,
    }),
    "addVariableService",
  );
  const list = await ok(
    await api.get(`/establishments/${establishmentId}/services`, {
      headers: { Authorization: `Bearer ${owner.token}` },
    }),
    "addVariableService:list",
  );
  return (
    (Array.isArray(list) ? list : []).find(
      (s: any) => s.name === payload.name,
    ) ?? payload
  );
}
export async function createVariablePriceBooking(
  api: APIRequestContext,
  cliente: SeededUser,
  args: {
    petId: string;
    petName: string;
    serviceName: string;
    establishmentId: string;
    establishmentName: string;
    scheduledAt: Date;
  },
): Promise<any> {
  return ok(
    await api.post("/bookings", {
      headers: { Authorization: `Bearer ${cliente.token}` },
      data: {
        userName: cliente.name,
        petId: args.petId,
        petName: args.petName,
        serviceName: args.serviceName,
        establishmentId: args.establishmentId,
        establishmentName: args.establishmentName,
        scheduledAt: args.scheduledAt.toISOString(),
        price: 0,
        priceVariable: true,
      },
    }),
    "createVariablePriceBooking",
  );
}
export async function registerDriver(
  api: APIRequestContext,
  owner: SeededUser,
  establishmentId: string,
  data: Partial<{
    name: string;
    phone: string;
    cpf: string;
    cnh: string;
    vehicleType: string;
    vehicleModel: string;
    vehiclePlate: string;
    photoUrl: string;
  }> = {},
): Promise<any> {
  const ts = Date.now() + counter++;
  const cpf = String(ts).slice(-11).padStart(11, "0");
  const plate = `E2E${String(ts).slice(-4)}`;
  const driver = await ok(
    await api.post("/drivers", {
      headers: auth(owner),
      data: {
        establishmentId,
        name: data.name ?? `Motorista E2E ${ts}`,
        phone: data.phone ?? "41988880000",
        cpf: data.cpf ?? cpf,
        cnh: data.cnh ?? String(ts).slice(-9),
        vehicleType: data.vehicleType ?? "CARRO",
        vehicleModel: data.vehicleModel ?? "Fiat Uno",
        vehiclePlate: data.vehiclePlate ?? plate,
        photoUrl: data.photoUrl,
      },
    }),
    "registerDriver",
  );
  await autoApproveDriver(api, driver.id);
  return driver;
}
export async function registerIndependentDriver(
  api: APIRequestContext,
  user: SeededUser,
  data: Partial<{
    cnh: string;
    vehicleType: string;
    vehicleModel: string;
    vehiclePlate: string;
  }> = {},
): Promise<any> {
  const ts = Date.now() + counter++;
  const plate = `I2E${String(ts).slice(-4)}`;
  const driver = await ok(
    await api.post("/drivers", {
      headers: auth(user),
      data: {
        name: user.name,
        phone: "41988880001",
        cpf: user.cpf,
        cnh: data.cnh ?? String(ts).slice(-9),
        vehicleType: data.vehicleType ?? "CARRO",
        vehicleModel: data.vehicleModel ?? "Fiat Uno",
        vehiclePlate: data.vehiclePlate ?? plate,
      },
    }),
    "registerIndependentDriver",
  );
  await autoApproveDriver(api, driver.id);
  return driver;
}
export async function registerVet(
  api: APIRequestContext,
  user: SeededUser,
  data: Partial<{
    crmv: string;
    especialidade: string;
    photoUrl: string;
    establishmentId: string;
  }> = {},
): Promise<any> {
  const ts = Date.now() + counter++;
  const vet = await ok(
    await api.post("/veterinarians", {
      headers: auth(user),
      data: {
        name: user.name,
        phone: "41988880002",
        cpf: user.cpf,
        crmv: data.crmv ?? `SP${ts.toString().slice(-5)}`,
        especialidade: data.especialidade ?? "Clínica geral",
        photoUrl: data.photoUrl,
        establishmentId: data.establishmentId,
      },
    }),
    "registerVet",
  );
  await autoApproveVet(api, vet.id);
  return vet;
}
let _adminCache: SeededUser | null = null;
export async function getAdmin(api: APIRequestContext): Promise<SeededUser> {
  if (_adminCache) return _adminCache;
  _adminCache = await loginUser(api, "admin@mypet.com", "admin123");
  return _adminCache;
}

async function autoApproveDriver(
  api: APIRequestContext,
  driverId: string,
): Promise<void> {
  try {
    const admin = await getAdmin(api);
    await api.patch(`/drivers/${driverId}/approve`, { headers: auth(admin) });
  } catch {}
}
async function autoApproveVet(
  api: APIRequestContext,
  vetId: string,
): Promise<void> {
  try {
    const admin = await getAdmin(api);
    await api.patch(`/veterinarians/${vetId}/approve`, {
      headers: auth(admin),
    });
  } catch {}
}

export async function getMyConversations(
  api: APIRequestContext,
  user: SeededUser,
): Promise<any[]> {
  return ok(
    await api.get("/conversations/me", { headers: auth(user) }),
    "getMyConversations",
  );
}
export async function loginUser(
  api: APIRequestContext,
  email: string,
  password: string,
): Promise<SeededUser> {
  const body = await ok(
    await api.post("/auth/login", { data: { email, password } }),
    "loginUser",
  );
  return {
    id: body.user?.id ?? "",
    name: body.user?.name ?? "",
    email,
    password,
    token: body.accessToken,
    role: body.user?.role ?? "CLIENTE",
    cpf: body.user?.cpf ?? "",
  };
}

export async function approveVet(
  api: APIRequestContext,
  admin: SeededUser,
  vetId: string,
): Promise<any> {
  return ok(
    await api.patch(`/veterinarians/${vetId}/approve`, {
      headers: { Authorization: `Bearer ${admin.token}` },
    }),
    "approveVet",
  );
}

export async function rejectVet(
  api: APIRequestContext,
  admin: SeededUser,
  vetId: string,
): Promise<any> {
  return ok(
    await api.patch(`/veterinarians/${vetId}/reject`, {
      headers: { Authorization: `Bearer ${admin.token}` },
    }),
    "rejectVet",
  );
}

export async function approveDriver(
  api: APIRequestContext,
  admin: SeededUser,
  driverId: string,
): Promise<any> {
  return ok(
    await api.patch(`/drivers/${driverId}/approve`, {
      headers: { Authorization: `Bearer ${admin.token}` },
    }),
    "approveDriver",
  );
}

export async function rejectDriver(
  api: APIRequestContext,
  admin: SeededUser,
  driverId: string,
): Promise<any> {
  return ok(
    await api.patch(`/drivers/${driverId}/reject`, {
      headers: { Authorization: `Bearer ${admin.token}` },
    }),
    "rejectDriver",
  );
}

export async function updateVetAvailability(
  api: APIRequestContext,
  vet: SeededUser,
  vetId: string,
  data: { disponivel?: boolean; atendeDomicilio?: boolean },
): Promise<any> {
  return ok(
    await api.patch(`/veterinarians/${vetId}/availability`, {
      headers: { Authorization: `Bearer ${vet.token}` },
      data,
    }),
    "updateVetAvailability",
  );
}

export async function deactivateDriver(
  api: APIRequestContext,
  owner: SeededUser,
  driverId: string,
): Promise<any> {
  return ok(
    await api.patch(`/drivers/${driverId}/deactivate`, {
      headers: auth(owner),
    }),
    "deactivateDriver",
  );
}
export async function advanceOrder(
  api: APIRequestContext,
  owner: SeededUser,
  orderId: string,
): Promise<any> {
  return ok(
    await api.patch(`/marketplace/orders/${orderId}/advance`, {
      headers: auth(owner),
    }),
    "advanceOrder",
  );
}
export async function seedFinalizedOrder(
  api: APIRequestContext,
  owner: SeededUser,
  estabId: string,
): Promise<{ cliente: SeededUser; product: any; orderId: string }> {
  const result = await seedPaidOrder(api, owner, estabId);
  await advanceOrder(api, owner, result.orderId);
  await advanceOrder(api, owner, result.orderId);
  return result;
}
export async function seedFullEstablishment(
  api: APIRequestContext,
  serviceName = "Banho E2E",
) {
  const owner = await registerUser(api, {
    role: "VENDEDOR",
    businessName: "Estab E2E",
  });
  const estab = await createEstablishment(api, owner, {
    name: `Pet Shop E2E ${Date.now()}`,
  });
  const service = await addService(api, owner, estab.id, { name: serviceName });
  await setSchedule(api, owner, estab.id);
  const product = await createProduct(api, owner, estab.id, {
    name: `Racao E2E ${Date.now()}`,
  });
  return { owner, estab, service, product };
}
export async function seedBooking(
  api: APIRequestContext,
  owner: SeededUser,
  estab: { id: string; name: string },
  opts: {
    serviceName?: string;
    pay?: boolean;
    finalStatus?: "CONFIRMADO" | "CONCLUIDO";
    price?: number;
  } = {},
) {
  const cliente = await registerUser(api, { role: "CLIENTE" });
  const pet = await createPet(api, cliente, {
    name: `Pet ${Date.now().toString().slice(-5)}`,
  });
  const scheduledAt = new Date();
  scheduledAt.setHours(12, 0, 0, 0);
  const serviceName = opts.serviceName ?? "Banho E2E";
  let booking = await createBooking(api, cliente, {
    petId: pet.id,
    petName: pet.name,
    serviceName,
    establishmentId: estab.id,
    establishmentName: estab.name,
    price: opts.price ?? 80,
    scheduledAt,
  });
  if (opts.pay || opts.finalStatus) {
    await payBooking(api, cliente, booking.id);
  }
  if (opts.finalStatus === "CONFIRMADO" || opts.finalStatus === "CONCLUIDO") {
    await updateBookingStatus(api, owner, booking.id, "CONFIRMADO");
  }
  if (opts.finalStatus === "CONCLUIDO") {
    await updateBookingStatus(api, owner, booking.id, "CONCLUIDO");
  }
  booking = await ok(
    await api.get(`/bookings/${booking.id}`, {
      headers: { Authorization: `Bearer ${cliente.token}` },
    }),
    "getBooking",
  );
  return { cliente, pet, booking, serviceName };
}
