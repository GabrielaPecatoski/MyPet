import 'package:flutter/material.dart';
import '../models/appointment.dart';
import '../repositories/history_repository.dart';

class HistoryProvider extends ChangeNotifier {
  final IHistoryRepository _repository;

  HistoryProvider(this._repository);

  List<AppointmentModel> _history = [];
  bool _loading = false;
  final Set<String> _reviewedBookingIds = {};

  List<AppointmentModel> get history => _history;
  bool get isLoading => _loading;
  Set<String> get reviewedBookingIds => _reviewedBookingIds;
  bool isReviewed(String bookingId) => _reviewedBookingIds.contains(bookingId);

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

      if (token != null) {
        try {
          _reviewedBookingIds
              .addAll(await _repository.reviewedBookingIds(token: token));
        } catch (_) {}
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<bool> submitReview({
    required String establishmentId,
    required String bookingId,
    required int rating,
    String? comment,
    required String token,
  }) async {
    var ok = true;
    try {
      await _repository.submitReview(
        establishmentId: establishmentId,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        token: token,
      );
    } catch (_) {
      ok = false;
    }
    _reviewedBookingIds.add(bookingId);
    notifyListeners();
    return ok;
  }
}
