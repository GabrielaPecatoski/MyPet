import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../repositories/driver_register_repository.dart';
import '../services/storage_service.dart';

class DriverRegisterProvider extends ChangeNotifier {
  final IDriverRegisterRepository _repository;

  DriverRegisterProvider(this._repository);

  bool _loading = false;
  String? _error;

  bool get isLoading => _loading;
  String? get error => _error;

  Future<DriverModel?> submit({
    required String token,
    String? establishmentId,
    required String name,
    required String phone,
    required String cpf,
    required String cnh,
    required String vehicleType,
    required String vehicleModel,
    required String vehiclePlate,
    String? cnhPhotoPath,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final driver = await _repository.register(
        token: token,
        establishmentId: establishmentId,
        name: name,
        phone: phone,
        cpf: cpf,
        cnh: cnh,
        vehicleType: vehicleType,
        vehicleModel: vehicleModel,
        vehiclePlate: vehiclePlate,
      );
      if (cnhPhotoPath != null) {
        await StorageService.saveCnhPhoto(cpf, cnhPhotoPath);
      }
      return driver;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
