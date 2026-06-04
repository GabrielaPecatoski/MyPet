import 'package:flutter/material.dart';
import '../models/driver.dart';
import '../models/veterinarian.dart';
import '../services/driver_service.dart';
import '../services/veterinarian_service.dart';

class EstablishmentStaffProvider extends ChangeNotifier {
  String? _establishmentId;
  String? _token;

  List<DriverModel> _drivers = [];
  List<VeterinarianModel> _vets = [];
  bool _loadingDrivers = false;
  bool _loadingVets = false;
  String? _errorDrivers;
  String? _errorVets;

  List<DriverModel> get drivers => _drivers;
  List<VeterinarianModel> get vets => _vets;
  bool get loadingDrivers => _loadingDrivers;
  bool get loadingVets => _loadingVets;
  String? get errorDrivers => _errorDrivers;
  String? get errorVets => _errorVets;

  void init({required String establishmentId, required String token}) {
    _establishmentId = establishmentId;
    _token = token;
  }


  Future<void> loadDrivers() async {
    if (_establishmentId == null || _token == null) return;
    _loadingDrivers = true;
    _errorDrivers = null;
    notifyListeners();
    try {
      _drivers = await DriverService.fetchByEstablishment(
        token: _token!,
        establishmentId: _establishmentId!,
      );
    } catch (_) {
      _errorDrivers = 'Erro ao carregar motoristas';
    } finally {
      _loadingDrivers = false;
      notifyListeners();
    }
  }

  Future<bool> addDriver({
    required String name, required String phone, required String cpf,
    required String cnh, required String vehicleType,
    required String vehicleModel, required String vehiclePlate,
  }) async {
    if (_establishmentId == null || _token == null) return false;
    try {
      await DriverService.register(
        token: _token!,
        establishmentId: _establishmentId,
        name: name, phone: phone, cpf: cpf,
        cnh: cnh, vehicleType: vehicleType,
        vehicleModel: vehicleModel, vehiclePlate: vehiclePlate,
      );
      await loadDrivers();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dissociateDriver(String driverId) async {
    if (_token == null) return false;
    try {
      await DriverService.dissociate(token: _token!, driverId: driverId);
      await loadDrivers();
      return true;
    } catch (_) {
      return false;
    }
  }


  Future<void> loadVets() async {
    if (_establishmentId == null || _token == null) return;
    _loadingVets = true;
    _errorVets = null;
    notifyListeners();
    try {
      _vets = await VeterinarianService.fetchByEstablishment(
        token: _token!,
        establishmentId: _establishmentId!,
      );
    } catch (_) {
      _errorVets = 'Erro ao carregar veterinários';
    } finally {
      _loadingVets = false;
      notifyListeners();
    }
  }

  Future<VeterinarianModel?> findVetByCpf(String cpf) async {
    if (_token == null) return null;
    return VeterinarianService.findByCpf(token: _token!, cpf: cpf);
  }

  Future<bool> associateVet(String vetId) async {
    if (_establishmentId == null || _token == null) return false;
    try {
      await VeterinarianService.associate(
        token: _token!, vetId: vetId,
        establishmentId: _establishmentId!,
      );
      await loadVets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> dissociateVet(String vetId) async {
    if (_token == null) return false;
    try {
      await VeterinarianService.dissociate(token: _token!, vetId: vetId);
      await loadVets();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> loadAll() async {
    await Future.wait([loadDrivers(), loadVets()]);
  }
}
