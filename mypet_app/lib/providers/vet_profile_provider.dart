import 'package:flutter/material.dart';
import '../models/veterinarian.dart';
import '../services/veterinarian_service.dart';

class VetProfileProvider extends ChangeNotifier {
  VeterinarianModel? _vet;
  bool _loading = false;
  bool _updating = false;
  String? _error;

  VeterinarianModel? get vet => _vet;
  bool get loading => _loading;
  bool get updating => _updating;
  String? get error => _error;
  bool get hasVet => _vet != null;
  bool get disponivel => _vet?.disponivel ?? false;
  bool get atendeDomicilio => _vet?.atendeDomicilio ?? false;
  bool get atende24h => _vet?.atende24h ?? false;
  bool get isAprovado => _vet?.isAprovado ?? false;

  Future<void> load({required String token, required String cpf}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _vet = await VeterinarianService.findByCpf(token: token, cpf: cpf);
    } catch (_) {
      _error = 'Erro ao carregar perfil do veterinário';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateAvailability({
    required String token,
    bool? disponivel,
    bool? atendeDomicilio,
    bool? atende24h,
  }) async {
    if (_vet == null) return false;
    _updating = true;
    _error = null;
    final prev = _vet!;
    _vet = _vet!.copyWith(
      disponivel: disponivel,
      atendeDomicilio: atendeDomicilio,
      atende24h: atende24h,
    );
    notifyListeners();
    try {
      _vet = await VeterinarianService.updateAvailability(
        token: token,
        vetId: _vet!.id,
        disponivel: disponivel,
        atendeDomicilio: atendeDomicilio,
        atende24h: atende24h,
      );
      return true;
    } catch (e) {
      _vet = prev;
      _error = e.toString().replaceAll('Exception: ', '');
      return false;
    } finally {
      _updating = false;
      notifyListeners();
    }
  }

  void clear() {
    _vet = null;
    _error = null;
    notifyListeners();
  }
}
