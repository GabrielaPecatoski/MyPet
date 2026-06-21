import { NotificationHandler } from "../src/modules/notification/infra/messaging/notification.handler";
import { BookingRoutingKey } from "@shared/contracts/events/booking-events.enum";
import { MarketplaceRoutingKey } from "@shared/contracts/events/marketplace-events.enum";
import { ReviewRoutingKey } from "@shared/contracts/events/review-events.enum";
import { UserAuthRoutingKey } from "@shared/contracts/events/user-auth-events.enum";

const makeDeps = () => ({
  rabbitMQService: { getChannel: jest.fn() },
  notificationService: { create: jest.fn().mockResolvedValue({ id: "n1" }) },
  deviceTokenRepo: { findTokenByUserId: jest.fn().mockResolvedValue(null) },
  mailService: {
    sendBookingReceived: jest.fn().mockResolvedValue(undefined),
    sendBookingConfirmed: jest.fn().mockResolvedValue(undefined),
    sendBookingCancelled: jest.fn().mockResolvedValue(undefined),
    sendOrderPlaced: jest.fn().mockResolvedValue(undefined),
    sendWelcome: jest.fn().mockResolvedValue(undefined),
  },
  fcmService: { sendPush: jest.fn().mockResolvedValue(undefined) },
});

type Deps = ReturnType<typeof makeDeps>;

// Acesso à handleMessage privado via cast
const dispatch = (handler: NotificationHandler, key: string, payload: unknown) =>
  (handler as unknown as { handleMessage(k: string, p: unknown): Promise<void> }).handleMessage(
    key,
    payload,
  );

describe("NotificationHandler — roteamento de mensagens (C9)", () => {
  let deps: Deps;
  let handler: NotificationHandler;

  beforeEach(() => {
    deps = makeDeps();
    handler = new NotificationHandler(
      deps.rabbitMQService as any,
      deps.notificationService as any,
      deps.deviceTokenRepo as any,
      deps.mailService as any,
      deps.fcmService as any,
    );
  });

  // ── booking.created ──────────────────────────────────────────────────────────

  it("booking.created → notificação BOOKING_CREATED para o estabelecimento", async () => {
    await dispatch(handler, BookingRoutingKey.CREATED, {
      bookingId: "b1",
      establishmentId: "estab-1",
      establishmentName: "PetShop X",
      clientName: "João",
      userEmail: "joao@email.com",
      serviceName: "Banho",
      scheduledAt: new Date().toISOString(),
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "estab-1", type: "BOOKING_CREATED" }),
    );
    expect(deps.mailService.sendBookingReceived).toHaveBeenCalledWith(
      "joao@email.com",
      "Banho",
      "PetShop X",
      expect.any(String),
    );
  });

  it("booking.created sem email → não envia e-mail", async () => {
    await dispatch(handler, BookingRoutingKey.CREATED, {
      bookingId: "b1",
      establishmentId: "estab-1",
      establishmentName: "PetShop X",
      clientName: "João",
      serviceName: "Banho",
      scheduledAt: new Date().toISOString(),
    });

    expect(deps.mailService.sendBookingReceived).not.toHaveBeenCalled();
  });

  // ── booking.status_updated ───────────────────────────────────────────────────

  it("status_updated CONFIRMADO → notificação BOOKING_CONFIRMED para o cliente", async () => {
    await dispatch(handler, BookingRoutingKey.STATUS_UPDATED, {
      bookingId: "b1",
      userId: "client-1",
      userEmail: "cliente@email.com",
      status: "CONFIRMADO",
      establishmentName: "PetShop X",
      serviceName: "Tosa",
      scheduledAt: new Date().toISOString(),
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "client-1", type: "BOOKING_CONFIRMED" }),
    );
    expect(deps.mailService.sendBookingConfirmed).toHaveBeenCalled();
  });

  it("status_updated RECUSADO → notificação BOOKING_REJECTED para o cliente", async () => {
    await dispatch(handler, BookingRoutingKey.STATUS_UPDATED, {
      bookingId: "b1",
      userId: "client-1",
      userEmail: "cliente@email.com",
      status: "RECUSADO",
      establishmentName: "PetShop X",
      serviceName: "Tosa",
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "client-1", type: "BOOKING_REJECTED" }),
    );
    expect(deps.mailService.sendBookingCancelled).toHaveBeenCalled();
  });

  // ── booking.canceled ─────────────────────────────────────────────────────────

  it("booking.canceled → notificação BOOKING_CANCELLED para o cliente", async () => {
    await dispatch(handler, BookingRoutingKey.CANCELED, {
      bookingId: "b1",
      userId: "client-1",
      userEmail: "cliente@email.com",
      serviceName: "Banho",
      establishmentName: "PetShop X",
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "client-1", type: "BOOKING_CANCELLED" }),
    );
    expect(deps.mailService.sendBookingCancelled).toHaveBeenCalledWith(
      "cliente@email.com",
      "Banho",
      "PetShop X",
    );
  });

  // ── booking.completed ────────────────────────────────────────────────────────

  it("booking.completed → notificação BOOKING_COMPLETED para o cliente", async () => {
    await dispatch(handler, BookingRoutingKey.COMPLETED, {
      bookingId: "b1",
      userId: "client-1",
      establishmentName: "PetShop X",
      serviceName: "Tosa",
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "client-1", type: "BOOKING_COMPLETED" }),
    );
  });

  // ── booking.reminder ─────────────────────────────────────────────────────────

  it("booking.reminder → notificação BOOKING_REMINDER para o cliente", async () => {
    await dispatch(handler, BookingRoutingKey.REMINDER, {
      bookingId: "b1",
      userId: "client-1",
      serviceName: "Banho",
      establishmentName: "PetShop X",
      scheduledAt: new Date().toISOString(),
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "client-1", type: "BOOKING_REMINDER" }),
    );
  });

  // ── marketplace.order_created ────────────────────────────────────────────────

  it("order.created → notificação ORDER_CREATED e e-mail", async () => {
    await dispatch(handler, MarketplaceRoutingKey.ORDER_CREATED, {
      orderId: "ord-1",
      userId: "client-1",
      userEmail: "cliente@email.com",
      total: 99.9,
      itemCount: 3,
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "client-1", type: "ORDER_CREATED" }),
    );
    expect(deps.mailService.sendOrderPlaced).toHaveBeenCalledWith(
      "cliente@email.com",
      "ord-1",
      99.9,
      3,
    );
  });

  // ── review.created ───────────────────────────────────────────────────────────

  it("review.created → notificação REVIEW_RECEIVED para o estabelecimento", async () => {
    await dispatch(handler, ReviewRoutingKey.CREATED, {
      reviewId: "rev-1",
      establishmentId: "estab-1",
      userId: "client-1",
      rating: 5,
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "estab-1", type: "REVIEW_RECEIVED" }),
    );
  });

  // ── user.created ─────────────────────────────────────────────────────────────

  it("user.created → notificação AUTH_WELCOME e e-mail de boas-vindas", async () => {
    await dispatch(handler, UserAuthRoutingKey.USER_CREATED, {
      userId: "user-new",
      name: "Maria",
      email: "maria@email.com",
    });

    expect(deps.notificationService.create).toHaveBeenCalledWith(
      expect.objectContaining({ userId: "user-new", type: "AUTH_WELCOME" }),
    );
    expect(deps.mailService.sendWelcome).toHaveBeenCalledWith("maria@email.com", "Maria");
  });
});
