import 'package:flutter/material.dart';
import '../models/establishment.dart';
import '../models/veterinarian.dart';
import '../services/establishment_service.dart';
import '../services/veterinarian_service.dart';

class EmergencyProvider extends ChangeNotifier {
  List<EstablishmentModel> _establishments = [];
  List<VeterinarianModel> _vets = [];
  bool _loadingEstabs = false;
  bool _loadingVets = false;
  String? _errorEstabs;
  String? _errorVets;

  List<EstablishmentModel> get establishments => _establishments;
  List<VeterinarianModel> get vets => _vets;
  bool get loadingEstabs => _loadingEstabs;
  bool get loadingVets => _loadingVets;
  String? get errorEstabs => _errorEstabs;
  String? get errorVets => _errorVets;

  Future<void> loadEstabs() async {
    _loadingEstabs = true;
    _errorEstabs = null;
    notifyListeners();
    try {
      _establishments = await EstablishmentService.fetchEmergency();
    } catch (_) {
      _errorEstabs = 'Não foi possível carregar os estabelecimentos de emergência.';
    } finally {
      _loadingEstabs = false;
      notifyListeners();
    }
  }

  Future<void> loadVets({String token = ''}) async {
    _loadingVets = true;
    _errorVets = null;
    notifyListeners();
    try {
      _vets = await VeterinarianService.fetchAvailable(token: token);
    } catch (_) {
      _errorVets = 'Não foi possível carregar os veterinários.';
    } finally {
      _loadingVets = false;
      notifyListeners();
    }
  }

  Future<void> loadAll({String token = ''}) async {
    await Future.wait([loadEstabs(), loadVets(token: token)]);
  }
}
