import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final IHistoryRepository _repository;

  HistoryProvider(this._repository);

  List<AppointmentModel> _history = [];
  bool _loading = false;

  List<AppointmentModel> get history => _history;
  bool get isLoading => _loading;

  Future<void> load(String userId, {String? token}) async {
    _loading = true;
    notifyListeners();
    try {
      final all = await _repository.getByUser(userId, token: token);

      if (token != null) {
        final now = DateTime.now();
        for (final b in all) {
          if (b.status == 'CONFIRMADO' && now.difference(b.date).inHours >= 4) {
            try {
              await _repository.markCompleted(b.id, token: token);
            } catch (_) {}
          }
        }
      }

      final refreshed = await _repository.getByUser(userId, token: token);
      _history = refreshed
          .where((b) => b.status == 'CONCLUIDO')
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}
