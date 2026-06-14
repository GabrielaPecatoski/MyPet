import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/constants.dart';
import '../models/appointment.dart';
import '../models/emergency_call.dart';
import '../models/veterinarian.dart';
import '../services/booking_service.dart';
import '../services/sse/sse_client.dart';
import '../services/veterinarian_service.dart';

class VetProfileProvider extends ChangeNotifier {
  VeterinarianModel? _vet;
  bool _loading = false;
  bool _updating = false;
  String? _error;
  List<EmergencyCallModel> _pendingCalls = [];
  SseSubscription? _emergencyStream;

  VeterinarianModel? get vet => _vet;
  bool get loading => _loading;
  bool get updating => _updating;
  String? get error => _error;
  bool get hasVet => _vet != null;
  bool get disponivel => _vet?.disponivel ?? false;
  bool get atendeDomicilio => _vet?.atendeDomicilio ?? false;
  bool get atende24h => _vet?.atende24h ?? false;
  bool get isAprovado => _vet?.isAprovado ?? false;
  List<EmergencyCallModel> get pendingCalls => _pendingCalls;
  int get pendingCallsCount => _pendingCalls.length;

  Future<List<EmergencyCallModel>> refreshPendingCalls(
      {required String token}) async {
    if (_vet == null) return _pendingCalls;
    final calls = await VeterinarianService.getPendingEmergencyCalls(
      token: token,
      vetId: _vet!.id,
    );
    final changed = calls.length != _pendingCalls.length ||
        !calls.every((c) => _pendingCalls.any((p) => p.id == c.id));
    _pendingCalls = calls;
    if (changed) notifyListeners();
    return _pendingCalls;
  }

  Future<void> acknowledgeCall(
      {required String token, required String callId}) async {
    await VeterinarianService.acknowledgeEmergencyCall(
        token: token, callId: callId);
    _pendingCalls = _pendingCalls.where((c) => c.id != callId).toList();
    notifyListeners();
  }

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

  Future<List<AppointmentModel>> fetchBookings({
    required String token,
    required String vetId,
  }) {
    return BookingService.fetchVetBookings(token: token, vetId: vetId);
  }

  void startEmergencyStream({
    required String token,
    required void Function() onCall,
  }) {
    stopEmergencyStream();
    final vet = _vet;
    if (vet == null) return;
    final url =
        '${ApiConstants.baseUrl}/notifications/stream/${vet.id}?token=$token';
    _emergencyStream = connectSse(url, (data) {
      try {
        final event = jsonDecode(data) as Map<String, dynamic>;
        if (event['type'] == 'EMERGENCY_VET_CALL') onCall();
      } catch (_) {}
    });
  }

  void stopEmergencyStream() {
    _emergencyStream?.close();
    _emergencyStream = null;
  }

  void clear() {
    _vet = null;
    _error = null;
    _pendingCalls = [];
    stopEmergencyStream();
    notifyListeners();
  }

  @override
  void dispose() {
    stopEmergencyStream();
    super.dispose();
  }
}
