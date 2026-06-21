import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../models/driver.dart';
import '../services/booking_service.dart';
import '../services/driver_service.dart';
import '../services/storage_service.dart';

class DriverProfileProvider extends ChangeNotifier {
  DriverModel? _driver;
  bool _loading = false;
  String? _error;
  String? _vehiclePhotoPath;
  String? _cnhPhotoPath;
  bool _settingOnline = false;
  List<AppointmentModel> _availableRides = [];
  bool _loadingRides = false;

  DriverModel? get driver => _driver;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasDriver => _driver != null;
  String? get vehiclePhotoPath => _vehiclePhotoPath;
  String? get cnhPhotoPath => _cnhPhotoPath;
  bool get online => _driver?.online ?? false;
  bool get settingOnline => _settingOnline;
  List<AppointmentModel> get availableRides => _availableRides;
  bool get loadingRides => _loadingRides;

  /// Liga/desliga a disponibilidade do motorista no backend.
  Future<bool> setOnline({required String token, required bool online}) async {
    if (_driver == null) return false;
    _settingOnline = true;
    notifyListeners();
    try {
      _driver = await DriverService.setOnline(
        token: token,
        driverId: _driver!.id,
        online: online,
      );
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _settingOnline = false;
      notifyListeners();
    }
  }

  /// Busca corridas de transporte disponíveis para este motorista.
  Future<void> loadAvailableRides({required String token}) async {
    if (_driver == null) return;
    _loadingRides = true;
    notifyListeners();
    try {
      _availableRides = await BookingService.fetchAvailableTransport(
        token: token,
        driverEstablishmentId: _driver!.establishmentId,
      );
    } catch (_) {
      _availableRides = [];
    } finally {
      _loadingRides = false;
      notifyListeners();
    }
  }

  /// Aceita uma corrida; em caso de sucesso ela sai da lista de disponíveis.
  Future<String?> acceptRide({
    required String token,
    required String bookingId,
  }) async {
    if (_driver == null) return 'Perfil de motorista não carregado';
    try {
      await BookingService.acceptTransport(
        token: token,
        bookingId: bookingId,
        driverId: _driver!.id,
        driverName: _driver!.name,
        driverPhotoUrl: _driver!.photoUrl,
      );
      _availableRides =
          _availableRides.where((r) => r.id != bookingId).toList();
      notifyListeners();
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<void> load({required String token, required String cpf}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        DriverService.findByCpf(token: token, cpf: cpf),
        StorageService.getVehiclePhoto(),
        StorageService.getCnhPhoto(cpf),
      ]);
      _driver = results[0] as DriverModel?;
      _vehiclePhotoPath = results[1] as String?;
      _cnhPhotoPath = results[2] as String?;
    } catch (_) {
      _error = 'Erro ao carregar perfil do motorista';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> saveVehiclePhoto(String path) async {
    await StorageService.saveVehiclePhoto(path);
    _vehiclePhotoPath = path;
    notifyListeners();
  }

  /// Persiste a foto de perfil do motorista no backend (data URL base64) para
  /// que ela apareça para os clientes (escolha de transporte, agenda etc.).
  Future<bool> updateProfilePhoto({
    required String token,
    required String photoUrl,
  }) async {
    if (_driver == null) return false;
    try {
      _driver = await DriverService.updatePhoto(
        token: token,
        driverId: _driver!.id,
        photoUrl: photoUrl,
      );
      notifyListeners();
      return true;
    } catch (_) {
      _error = 'Erro ao salvar foto de perfil';
      notifyListeners();
      return false;
    }
  }

  Future<void> saveCnhPhoto(String cpf, String path) async {
    await StorageService.saveCnhPhoto(cpf, path);
    _cnhPhotoPath = path;
    notifyListeners();
  }

  Future<bool> dissociate({required String token}) async {
    if (_driver == null) return false;
    try {
      await DriverService.dissociate(token: token, driverId: _driver!.id);
      await load(token: token, cpf: _driver!.cpf);
      return true;
    } catch (_) {
      return false;
    }
  }

  void clear() {
    _driver = null;
    _error = null;
    notifyListeners();
  }
}
