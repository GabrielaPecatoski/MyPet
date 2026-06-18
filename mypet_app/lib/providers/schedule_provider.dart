import 'package:flutter/material.dart';
import '../models/availability.dart';
import '../models/driver.dart';
import '../models/pet.dart';
import '../models/establishment.dart';
import '../repositories/schedule_repository.dart';

class ScheduleProvider extends ChangeNotifier {
  final IScheduleRepository _repository;

  ScheduleProvider(this._repository);

  List<PetModel> _pets = [];
  bool _loadingPets = false;
  List<ServiceModel> _services = [];
  bool _loadingServices = false;
  List<DriverModel> _drivers = [];
  bool _loadingDrivers = false;
  List<TimeSlotModel> _slots = [];
  bool _loadingSlots = false;

  List<PetModel> get pets => _pets;
  bool get loadingPets => _loadingPets;
  List<ServiceModel> get services => _services;
  bool get loadingServices => _loadingServices;
  List<DriverModel> get drivers => _drivers;
  bool get loadingDrivers => _loadingDrivers;
  List<TimeSlotModel> get slots => _slots;
  bool get loadingSlots => _loadingSlots;

  Future<void> loadPets(String userId, {String? token}) async {
    _loadingPets = true;
    notifyListeners();
    try {
      _pets = await _repository.pets(userId, token: token);
    } catch (_) {
    } finally {
      _loadingPets = false;
      notifyListeners();
    }
  }

  Future<void> loadServicesAndDrivers(String estabId, {String? token}) async {
    _loadingServices = true;
    notifyListeners();
    try {
      _services = await _repository.services(estabId);
    } catch (_) {
    } finally {
      _loadingServices = false;
      notifyListeners();
    }
    if (token != null) await loadDrivers(estabId, token: token);
  }

  Future<void> loadDrivers(String estabId, {required String token}) async {
    _loadingDrivers = true;
    notifyListeners();
    try {
      _drivers = await _repository.activeDrivers(estabId, token: token);
    } catch (_) {
    } finally {
      _loadingDrivers = false;
      notifyListeners();
    }
  }

  Future<String?> loadSlots(
      {required String estabId, required String date, required String token}) async {
    _loadingSlots = true;
    _slots = [];
    notifyListeners();
    String? error;
    try {
      _slots = await _repository.slots(
          estabId: estabId, date: date, token: token);
    } catch (e) {
      _slots = [];
      error = e.toString();
    } finally {
      _loadingSlots = false;
      notifyListeners();
    }
    return error;
  }

  void clearSlots() {
    _slots = [];
    notifyListeners();
  }
}
