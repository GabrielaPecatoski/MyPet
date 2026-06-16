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

  /// Serviço padrão para consulta com veterinário SEM clínica vinculada:
  /// atendimento domiciliar, preço variável (sob consulta) — vai direto para
  /// PENDENTE, sem etapa de pagamento.
  static ServiceModel get homeVisitService => ServiceModel(
        id: 'home-visit-consulta',
        name: 'Consulta domiciliar',
        price: 0,
        priceVariable: true,
        durationMinutes: 60,
        description:
            'Atendimento no endereço do tutor. O valor é combinado com o veterinário.',
        categoria: 'atendimento_domiciliar',
      );

  /// Modo domiciliar (vet sem clínica): oferece só a consulta domiciliar e
  /// nenhum motorista (o próprio veterinário se desloca até o tutor).
  void loadHomeVisitServices() {
    _services = [homeVisitService];
    _drivers = [];
    _loadingServices = false;
    _loadingDrivers = false;
    notifyListeners();
  }

  /// Slots genéricos (08h–18h, de hora em hora) para o modo domiciliar, já que
  /// não há disponibilidade de estabelecimento. Horários passados ficam
  /// indisponíveis; o veterinário confirma ou recusa na agenda dele.
  void loadHomeVisitSlots(DateTime date) {
    final now = DateTime.now();
    final isToday =
        date.year == now.year && date.month == now.month && date.day == now.day;
    _slots = [
      for (var h = 8; h <= 17; h++)
        TimeSlotModel(
          time: '${h.toString().padLeft(2, '0')}:00',
          available: !(isToday && h <= now.hour),
        ),
    ];
    _loadingSlots = false;
    notifyListeners();
  }
}
