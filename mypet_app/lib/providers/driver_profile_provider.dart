import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../services/driver_service.dart';
import '../services/storage_service.dart';

class DriverProfileProvider extends ChangeNotifier {
  DriverModel? _driver;
  bool _loading = false;
  String? _error;
  String? _vehiclePhotoPath;
  String? _cnhPhotoPath;

  DriverModel? get driver => _driver;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasDriver => _driver != null;
  String? get vehiclePhotoPath => _vehiclePhotoPath;
  String? get cnhPhotoPath => _cnhPhotoPath;

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
