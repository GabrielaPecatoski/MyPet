import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/models/appointment.dart';

void main() {
  // JSON mínimo obrigatório
  Map<String, dynamic> baseJson({
    String petBreed = '',
    int petAge = 0,
    String establishmentAddress = '',
  }) =>
      {
        'id': 'booking-1',
        'userId': 'user-1',
        'userName': 'João Silva',
        'petId': 'pet-1',
        'petName': 'Rex',
        'petBreed': petBreed,
        'petAge': petAge,
        'serviceName': 'Banho',
        'establishmentId': 'estab-1',
        'establishmentName': 'PetShop X',
        'establishmentAddress': establishmentAddress,
        'scheduledAt': '2026-07-15T14:00:00.000Z',
        'status': 'PENDENTE',
        'price': 60.0,
      };

  group('AppointmentModel.fromJson — campos obrigatórios', () {
    test('parseia id, userId, petName, serviceName corretamente', () {
      final ap = AppointmentModel.fromJson(baseJson());
      expect(ap.id, 'booking-1');
      expect(ap.userId, 'user-1');
      expect(ap.petName, 'Rex');
      expect(ap.serviceName, 'Banho');
      expect(ap.establishmentName, 'PetShop X');
      expect(ap.price, 60.0);
      expect(ap.status, 'PENDENTE');
    });

    test('parseia scheduledAt e extrai time corretamente', () {
      final ap = AppointmentModel.fromJson(baseJson());
      expect(ap.date.year, 2026);
      expect(ap.date.month, 7);
      expect(ap.date.day, 15);
      expect(ap.time, '14:00');
    });
  });

  // ── C36: campos petBreed, petAge, establishmentAddress ──────────────────────

  group('AppointmentModel.fromJson — campos C36', () {
    test('parseia petBreed quando presente', () {
      final ap = AppointmentModel.fromJson(baseJson(petBreed: 'Labrador'));
      expect(ap.petBreed, 'Labrador');
    });

    test('parseia petAge quando presente', () {
      final ap = AppointmentModel.fromJson(baseJson(petAge: 3));
      expect(ap.petAge, 3);
    });

    test('parseia establishmentAddress quando presente', () {
      final ap = AppointmentModel.fromJson(
          baseJson(establishmentAddress: 'Rua das Flores, 100'));
      expect(ap.establishmentAddress, 'Rua das Flores, 100');
    });

    test('retorna string vazia quando petBreed está ausente do JSON', () {
      final json = Map<String, dynamic>.from(baseJson());
      json.remove('petBreed');
      final ap = AppointmentModel.fromJson(json);
      expect(ap.petBreed, '');
    });

    test('retorna 0 quando petAge está ausente do JSON', () {
      final json = Map<String, dynamic>.from(baseJson());
      json.remove('petAge');
      final ap = AppointmentModel.fromJson(json);
      expect(ap.petAge, 0);
    });

    test('retorna string vazia quando establishmentAddress está ausente do JSON', () {
      final json = Map<String, dynamic>.from(baseJson());
      json.remove('establishmentAddress');
      final ap = AppointmentModel.fromJson(json);
      expect(ap.establishmentAddress, '');
    });

    test('parseia todos os três campos juntos', () {
      final ap = AppointmentModel.fromJson(baseJson(
        petBreed: 'Golden Retriever',
        petAge: 5,
        establishmentAddress: 'Av. Brasil, 200 — São Paulo',
      ));
      expect(ap.petBreed, 'Golden Retriever');
      expect(ap.petAge, 5);
      expect(ap.establishmentAddress, 'Av. Brasil, 200 — São Paulo');
    });
  });

  // ── Status helpers ───────────────────────────────────────────────────────────

  group('AppointmentModel — status helpers', () {
    AppointmentModel make(String status) =>
        AppointmentModel.fromJson({...baseJson(), 'status': status});

    test('isPendente retorna true apenas para PENDENTE', () {
      expect(make('PENDENTE').isPendente, isTrue);
      expect(make('CONFIRMADO').isPendente, isFalse);
    });

    test('isConfirmado retorna true apenas para CONFIRMADO', () {
      expect(make('CONFIRMADO').isConfirmado, isTrue);
      expect(make('PENDENTE').isConfirmado, isFalse);
    });

    test('statusLabel traduz todos os status', () {
      expect(make('PENDENTE').statusLabel, 'Pendente');
      expect(make('CONFIRMADO').statusLabel, 'Confirmado');
      expect(make('RECUSADO').statusLabel, 'Recusado');
      expect(make('CANCELADO').statusLabel, 'Cancelado');
      expect(make('CONCLUIDO').statusLabel, 'Concluído');
    });

    test('canCancel é true para PENDENTE', () {
      expect(make('PENDENTE').canCancel, isTrue);
    });

    test('canCancel é false para CONCLUIDO', () {
      expect(make('CONCLUIDO').canCancel, isFalse);
    });
  });

  // ── Lida com JSON incompleto ─────────────────────────────────────────────────

  group('AppointmentModel.fromJson — JSON incompleto', () {
    test('usa valores padrão quando campos opcionais faltam', () {
      final minimal = <String, dynamic>{
        'id': 'b1',
        'petName': 'Bolt',
        'serviceName': 'Consulta',
        'establishmentName': 'Clínica',
        'scheduledAt': '2026-01-01T09:00:00.000Z',
        'status': 'PENDENTE',
        'price': 0,
      };
      final ap = AppointmentModel.fromJson(minimal);
      expect(ap.userId, '');
      expect(ap.petBreed, '');
      expect(ap.petAge, 0);
      expect(ap.establishmentAddress, '');
    });
  });
}
