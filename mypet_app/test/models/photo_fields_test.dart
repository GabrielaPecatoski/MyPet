import 'package:flutter_test/flutter_test.dart';
import 'package:mypet_app/models/appointment.dart';
import 'package:mypet_app/models/driver.dart';
import 'package:mypet_app/models/veterinarian.dart';

void main() {
  const dataUrl = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAAB';

  group('VeterinarianModel.fromJson — photoUrl', () {
    Map<String, dynamic> base({String? photoUrl}) => {
          'id': 'vet-1',
          'name': 'Dra Ana',
          'phone': '41999990000',
          'cpf': '12345678901',
          'crmv': 'SP-12345',
          'photoUrl': ?photoUrl,
        };

    test('parseia photoUrl quando presente', () {
      final vet = VeterinarianModel.fromJson(base(photoUrl: dataUrl));
      expect(vet.photoUrl, dataUrl);
    });

    test('photoUrl é null quando ausente', () {
      expect(VeterinarianModel.fromJson(base()).photoUrl, isNull);
    });

    test('copyWith mantém photoUrl existente e permite trocar', () {
      final vet = VeterinarianModel.fromJson(base(photoUrl: dataUrl));
      expect(vet.copyWith(disponivel: true).photoUrl, dataUrl);
      expect(vet.copyWith(photoUrl: 'data:image/png;base64,ZZZ').photoUrl,
          'data:image/png;base64,ZZZ');
    });
  });

  group('DriverModel.fromJson — photoUrl', () {
    Map<String, dynamic> base({String? photoUrl}) => {
          'id': 'drv-1',
          'name': 'Carlos',
          'phone': '41988880000',
          'cpf': '98765432100',
          'cnh': '123456789',
          'vehicleType': 'CARRO',
          'vehicleModel': 'Fiat Uno',
          'vehiclePlate': 'ABC1D23',
          'photoUrl': ?photoUrl,
        };

    test('parseia photoUrl quando presente', () {
      expect(DriverModel.fromJson(base(photoUrl: dataUrl)).photoUrl, dataUrl);
    });

    test('photoUrl é null quando ausente', () {
      expect(DriverModel.fromJson(base()).photoUrl, isNull);
    });
  });

  group('AppointmentModel.fromJson — driverPhotoUrl', () {
    Map<String, dynamic> base({String? driverPhotoUrl, String? driverName}) => {
          'id': 'b1',
          'petName': 'Rex',
          'serviceName': 'Banho',
          'establishmentName': 'PetShop X',
          'scheduledAt': '2026-07-15T14:00:00.000Z',
          'status': 'CONFIRMADO',
          'price': 80.0,
          'driverName': ?driverName,
          'driverPhotoUrl': ?driverPhotoUrl,
        };

    test('parseia driverPhotoUrl + driverName quando presentes', () {
      final ap = AppointmentModel.fromJson(
          base(driverPhotoUrl: dataUrl, driverName: 'Carlos'));
      expect(ap.driverPhotoUrl, dataUrl);
      expect(ap.driverName, 'Carlos');
    });

    test('driverPhotoUrl é null quando ausente', () {
      expect(AppointmentModel.fromJson(base()).driverPhotoUrl, isNull);
    });
  });
}
