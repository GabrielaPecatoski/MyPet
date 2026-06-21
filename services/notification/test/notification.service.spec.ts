import { firstValueFrom, take, toArray } from "rxjs";
import { NotificationService } from "../src/modules/notification/application/services/notification.service";
import { Notification } from "../src/modules/notification/domain/models/notification.entity";

const makeNotification = (overrides: Partial<Notification> = {}): Notification =>
  ({
    id: "notif-1",
    userId: "user-1",
    title: "Teste",
    body: "Corpo",
    type: "BOOKING_CONFIRMED",
    read: false,
    createdAt: new Date(),
    markAsRead: jest.fn(),
    ...overrides,
  } as unknown as Notification);

const makeMockRepo = () => ({
  create: jest.fn().mockResolvedValue(makeNotification()),
  findByUserId: jest.fn().mockResolvedValue([]),
  countUnread: jest.fn().mockResolvedValue(0),
  findById: jest.fn().mockResolvedValue(null),
  update: jest.fn().mockResolvedValue(undefined),
  markAllAsRead: jest.fn().mockResolvedValue({ ok: true }),
});

const makeMockDeviceRepo = () => ({
  findTokenByUserId: jest.fn().mockResolvedValue(null),
  save: jest.fn().mockResolvedValue(undefined),
  deleteByUserId: jest.fn().mockResolvedValue(undefined),
});

describe("NotificationService", () => {
  let service: NotificationService;
  let repo: ReturnType<typeof makeMockRepo>;
  let deviceRepo: ReturnType<typeof makeMockDeviceRepo>;

  beforeEach(() => {
    repo = makeMockRepo();
    deviceRepo = makeMockDeviceRepo();
    service = new NotificationService(repo as any, deviceRepo as any);
  });

  // ── C9/C35: create() persiste e emite no stream ─────────────────────────────

  describe("create()", () => {
    it("chama notificationRepo.create com os dados corretos", async () => {
      await service.create({
        userId: "user-1",
        title: "Nova reserva",
        body: "Reserva confirmada",
        type: "BOOKING_CONFIRMED",
      });

      expect(repo.create).toHaveBeenCalledTimes(1);
      const arg = repo.create.mock.calls[0][0] as Notification;
      expect(arg.userId).toBe("user-1");
      expect(arg.title).toBe("Nova reserva");
      expect(arg.type).toBe("BOOKING_CONFIRMED");
    });

    it("emite evento no stream SSE após salvar", async () => {
      const streamPromise = firstValueFrom(
        service.getStream("user-1").pipe(take(1)),
      );

      await service.create({
        userId: "user-1",
        title: "Reserva confirmada",
        body: "Seu agendamento foi confirmado",
        type: "BOOKING_CONFIRMED",
      });

      const event = await streamPromise;
      expect(event).toBeDefined();
      expect((event.data as Record<string, unknown>)["type"]).toBe("BOOKING_CONFIRMED");
      expect((event.data as Record<string, unknown>)["title"]).toBe("Reserva confirmada");
    });

    it("NÃO emite no stream de outro usuário", async () => {
      const received: unknown[] = [];
      const sub = service.getStream("user-2").subscribe((e) => received.push(e));

      await service.create({
        userId: "user-1",
        title: "Só para user-1",
        body: "...",
        type: "BOOKING_CREATED",
      });

      // Aguarda microtask para garantir que nenhum evento chegou
      await new Promise((r) => setTimeout(r, 10));
      sub.unsubscribe();
      expect(received).toHaveLength(0);
    });

    it("emite em múltiplos streams do mesmo userId", async () => {
      const p1 = firstValueFrom(service.getStream("user-1").pipe(take(1)));
      const p2 = firstValueFrom(service.getStream("user-1").pipe(take(1)));

      await service.create({
        userId: "user-1",
        title: "Msg",
        body: "...",
        type: "ORDER_CREATED",
      });

      const [e1, e2] = await Promise.all([p1, p2]);
      expect((e1.data as Record<string, unknown>)["type"]).toBe("ORDER_CREATED");
      expect((e2.data as Record<string, unknown>)["type"]).toBe("ORDER_CREATED");
    });
  });

  // ── C35: heartbeat incluído no stream ───────────────────────────────────────

  describe("getStream() — heartbeat", () => {
    beforeEach(() => jest.useFakeTimers());
    afterEach(() => jest.useRealTimers());

    it("emite ping a cada 25 s", async () => {
      const events: unknown[] = [];
      const sub = service.getStream("user-1").pipe(take(3)).subscribe((e) => events.push(e));

      jest.advanceTimersByTime(25_000);
      jest.advanceTimersByTime(25_000);
      jest.advanceTimersByTime(25_000);

      await Promise.resolve(); // flush microtasks
      sub.unsubscribe();

      const pings = events.filter(
        (e) => (e as { data: Record<string, unknown> }).data?.["type"] === "ping",
      );
      expect(pings.length).toBeGreaterThanOrEqual(3);
    });
  });

  // ── Delegação ao repositório ─────────────────────────────────────────────────

  describe("listByUser()", () => {
    it("delega para notificationRepo.findByUserId", async () => {
      const notif = makeNotification();
      repo.findByUserId.mockResolvedValue([notif]);

      const result = await service.listByUser("user-1");

      expect(repo.findByUserId).toHaveBeenCalledWith("user-1");
      expect(result).toHaveLength(1);
    });
  });

  describe("countUnread()", () => {
    it("retorna { count } do repositório", async () => {
      repo.countUnread.mockResolvedValue(5);

      const result = await service.countUnread("user-1");

      expect(result).toEqual({ count: 5 });
      expect(repo.countUnread).toHaveBeenCalledWith("user-1");
    });
  });

  describe("markAsRead()", () => {
    it("chama markAsRead na entidade e atualiza no repositório", async () => {
      const notif = makeNotification();
      repo.findById.mockResolvedValue(notif);

      await service.markAsRead("notif-1");

      expect(repo.findById).toHaveBeenCalledWith("notif-1");
      expect(notif.markAsRead).toHaveBeenCalled();
      expect(repo.update).toHaveBeenCalledWith(notif);
    });

    it("lança NotFoundException quando notificação não existe", async () => {
      repo.findById.mockResolvedValue(null);

      await expect(service.markAsRead("inexistente")).rejects.toThrow(
        "Notificação não encontrada",
      );
    });
  });

  describe("markAllAsRead()", () => {
    it("delega para o repositório", async () => {
      const result = await service.markAllAsRead("user-1");

      expect(repo.markAllAsRead).toHaveBeenCalledWith("user-1");
      expect(result).toEqual({ ok: true });
    });
  });

  describe("saveDeviceToken()", () => {
    it("salva token via deviceTokenRepo", async () => {
      await service.saveDeviceToken("user-1", "fcm-token-abc", "android");

      expect(deviceRepo.save).toHaveBeenCalledWith("user-1", "fcm-token-abc", "android");
    });
  });

  describe("removeDeviceToken()", () => {
    it("remove token via deviceTokenRepo", async () => {
      await service.removeDeviceToken("user-1");

      expect(deviceRepo.deleteByUserId).toHaveBeenCalledWith("user-1");
    });
  });
});
