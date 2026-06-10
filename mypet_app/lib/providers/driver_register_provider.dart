import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../repositories/driver_register_repository.dart';

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
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      return await _repository.register(
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
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      return null;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
