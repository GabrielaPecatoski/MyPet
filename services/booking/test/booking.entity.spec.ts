import { Booking } from "../src/modules/booking/bookings/domain/models/booking.entity";
import { BookingDto } from "../src/modules/booking/bookings/application/dto/booking.dto";

const baseProps = {
  userId: "user-1",
  userName: "João",
  userEmail: "joao@email.com",
  petId: "pet-1",
  petName: "Rex",
  serviceName: "Banho",
  establishmentId: "estab-1",
  establishmentName: "PetShop X",
  scheduledAt: new Date("2026-07-10T14:00:00Z"),
  price: 50,
  status: "PENDENTE" as const,
};

describe("Booking entity (C36 — campos petBreed / petAge / establishmentAddress)", () => {

  describe("restore()", () => {
    it("popula petBreed e petAge quando fornecidos", () => {
      const b = Booking.restore({
        ...baseProps,
        petBreed: "Labrador",
        petAge: 3,
      })!;

      expect(b.petBreed).toBe("Labrador");
      expect(b.petAge).toBe(3);
    });

    it("popula establishmentAddress quando fornecido", () => {
      const b = Booking.restore({
        ...baseProps,
        establishmentAddress: "Rua das Flores, 100",
      })!;

      expect(b.establishmentAddress).toBe("Rua das Flores, 100");
    });

    it("retorna string vazia quando petBreed é omitido", () => {
      const b = Booking.restore(baseProps)!;
      expect(b.petBreed).toBe("");
    });

    it("retorna 0 quando petAge é omitido", () => {
      const b = Booking.restore(baseProps)!;
      expect(b.petAge).toBe(0);
    });

    it("retorna string vazia quando establishmentAddress é omitido", () => {
      const b = Booking.restore(baseProps)!;
      expect(b.establishmentAddress).toBe("");
    });

    it("lida com valores null como ausentes", () => {
      const b = Booking.restore({
        ...baseProps,
        petBreed: null,
        petAge: null,
        establishmentAddress: null,
      })!;

      expect(b.petBreed).toBe("");
      expect(b.petAge).toBe(0);
      expect(b.establishmentAddress).toBe("");
    });

    it("retorna null quando props é undefined", () => {
      expect(Booking.restore(undefined)).toBeNull();
    });

    it("preserva os demais campos sem alteração", () => {
      const b = Booking.restore({
        ...baseProps,
        petBreed: "Poodle",
        petAge: 2,
        establishmentAddress: "Av. Brasil, 200",
      })!;

      expect(b.userId).toBe("user-1");
      expect(b.petName).toBe("Rex");
      expect(b.serviceName).toBe("Banho");
      expect(b.price).toBe(50);
      expect(b.status).toBe("PENDENTE");
    });
  });

  describe("BookingDto.fromBooking() — campos novos incluídos na resposta", () => {
    it("inclui petBreed na resposta", () => {
      const b = Booking.restore({ ...baseProps, petBreed: "Golden Retriever" })!;
      const dto = BookingDto.fromBooking(b)!;
      expect(dto.petBreed).toBe("Golden Retriever");
    });

    it("inclui petAge na resposta", () => {
      const b = Booking.restore({ ...baseProps, petAge: 5 })!;
      const dto = BookingDto.fromBooking(b)!;
      expect(dto.petAge).toBe(5);
    });

    it("inclui establishmentAddress na resposta", () => {
      const b = Booking.restore({ ...baseProps, establishmentAddress: "Rua A, 10" })!;
      const dto = BookingDto.fromBooking(b)!;
      expect(dto.establishmentAddress).toBe("Rua A, 10");
    });

    it("omite petBreed quando vazio (undefined na resposta)", () => {
      const b = Booking.restore(baseProps)!;
      const dto = BookingDto.fromBooking(b)!;
      expect(dto.petBreed).toBeUndefined();
    });

    it("omite petAge quando zero (undefined na resposta)", () => {
      const b = Booking.restore(baseProps)!;
      const dto = BookingDto.fromBooking(b)!;
      expect(dto.petAge).toBeUndefined();
    });

    it("omite establishmentAddress quando vazio (undefined na resposta)", () => {
      const b = Booking.restore(baseProps)!;
      const dto = BookingDto.fromBooking(b)!;
      expect(dto.establishmentAddress).toBeUndefined();
    });

    it("retorna null quando booking é null", () => {
      expect(BookingDto.fromBooking(null)).toBeNull();
    });

    it("inclui todos os campos obrigatórios", () => {
      const b = Booking.restore(baseProps)!;
      const dto = BookingDto.fromBooking(b)!;

      expect(dto.userId).toBe("user-1");
      expect(dto.petName).toBe("Rex");
      expect(dto.serviceName).toBe("Banho");
      expect(dto.price).toBe(50);
      expect(dto.status).toBe("PENDENTE");
    });
  });
});
