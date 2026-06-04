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
  bool get disponivel => _vet?.disponivel ?? true;
  bool get atendeDomicilio => _vet?.atendeDomicilio ?? false;

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

  Future<void> updateAvailability({
    required String token,
    required bool disponivel,
    required bool atendeDomicilio,
  }) async {
    if (_vet == null) return;
    _updating = true;
    final prevDisp = _vet!.disponivel;
    final prevDom = _vet!.atendeDomicilio;
    _vet = _vet!.copyWith(disponivel: disponivel, atendeDomicilio: atendeDomicilio);
    notifyListeners();
    try {
      _vet = await VeterinarianService.updateAvailability(
        token: token,
        vetId: _vet!.id,
        disponivel: disponivel,
        atendeDomicilio: atendeDomicilio,
      );
    } catch (_) {
      _vet = _vet!.copyWith(disponivel: prevDisp, atendeDomicilio: prevDom);
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
