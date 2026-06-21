import { BookingService } from "../src/modules/booking/bookings/application/services/booking.service";
import { Booking } from "../src/modules/booking/bookings/domain/models/booking.entity";

const makeRepo = () => ({
  create: jest.fn().mockResolvedValue(undefined),
  update: jest.fn().mockResolvedValue(undefined),
  delete: jest.fn().mockResolvedValue(undefined),
  findById: jest.fn().mockResolvedValue(null),
  findByUserId: jest.fn().mockResolvedValue([]),
  findByEstablishmentId: jest.fn().mockResolvedValue([]),
  findUpcoming: jest.fn().mockResolvedValue([]),
});

const makeMessaging = () => ({
  assertExchange: jest.fn().mockResolvedValue(undefined),
  publish: jest.fn().mockResolvedValue(undefined),
});

const makeDto = (overrides = {}) => ({
  petId: "pet-1",
  petName: "Rex",
  petBreed: "Labrador",
  petAge: 3,
  serviceName: "Banho",
  establishmentId: "estab-1",
  establishmentName: "PetShop X",
  establishmentAddress: "Rua das Flores, 100",
  scheduledAt: new Date("2026-07-15T10:00:00Z").toISOString(),
  price: 60,
  ...overrides,
});

describe("BookingService (C36)", () => {
  let service: BookingService;
  let repo: ReturnType<typeof makeRepo>;
  let messaging: ReturnType<typeof makeMessaging>;

  beforeEach(() => {
    repo = makeRepo();
    messaging = makeMessaging();
    service = new BookingService(repo as any, messaging as any);
  });

  afterEach(() => {
    service.onModuleDestroy();
  });

  describe("create()", () => {
    it("persiste petBreed, petAge e establishmentAddress no banco", async () => {
      await service.create("user-1", "user@email.com", makeDto());

      expect(repo.create).toHaveBeenCalledTimes(1);
      const saved: Booking = repo.create.mock.calls[0][0];
      expect(saved.petBreed).toBe("Labrador");
      expect(saved.petAge).toBe(3);
      expect(saved.establishmentAddress).toBe("Rua das Flores, 100");
    });

    it("inclui petBreed e petAge na resposta DTO", async () => {
      const result = await service.create("user-1", "user@email.com", makeDto());

      expect(result.petBreed).toBe("Labrador");
      expect(result.petAge).toBe(3);
      expect(result.establishmentAddress).toBe("Rua das Flores, 100");
    });

    it("funciona sem petBreed, petAge e establishmentAddress (campos opcionais)", async () => {
      const dto = makeDto({ petBreed: undefined, petAge: undefined, establishmentAddress: undefined });
      const result = await service.create("user-1", "user@email.com", dto);

      expect(result.petBreed).toBeUndefined();
      expect(result.petAge).toBeUndefined();
      expect(result.establishmentAddress).toBeUndefined();
    });

    it("publica evento booking.created no RabbitMQ", async () => {
      await service.create("user-1", "user@email.com", makeDto());

      expect(messaging.publish).toHaveBeenCalledWith(
        expect.any(String),
        "booking.created",
        expect.objectContaining({ establishmentId: "estab-1" }),
      );
    });

    it("calcula o preço total a partir dos serviços quando fornecidos", async () => {
      const dto = makeDto({
        price: undefined,
        services: [
          { id: "s1", name: "Banho", price: 40, durationMinutes: 60 },
          { id: "s2", name: "Tosa", price: 30, durationMinutes: 30 },
        ],
      });

      const result = await service.create("user-1", "user@email.com", dto);
      expect(result.price).toBe(70);
    });

    it("define status inicial como PENDENTE", async () => {
      const result = await service.create("user-1", "user@email.com", makeDto());
      expect(result.status).toBe("PENDENTE");
    });
  });

  describe("updateStatus()", () => {
    it("lança NotFoundException para booking inexistente", async () => {
      repo.findById.mockResolvedValue(null);

      await expect(service.updateStatus("naoexiste", "CONFIRMADO")).rejects.toThrow(
        "Agendamento não encontrado",
      );
    });

    it("atualiza status e publica evento STATUS_UPDATED ao confirmar", async () => {
      const existing = Booking.restore({
        id: "b-1",
        userId: "user-1",
        userName: "João",
        petId: "pet-1",
        petName: "Rex",
        serviceName: "Banho",
        establishmentId: "estab-1",
        establishmentName: "PetShop X",
        scheduledAt: new Date(),
        price: 60,
        status: "PENDENTE",
      })!;
      repo.findById.mockResolvedValue(existing);

      await service.updateStatus("b-1", "CONFIRMADO");

      expect(repo.update).toHaveBeenCalled();
      expect(messaging.publish).toHaveBeenCalledWith(
        expect.any(String),
        "booking.status-updated",
        expect.objectContaining({ status: "CONFIRMADO" }),
      );
    });
  });
});
