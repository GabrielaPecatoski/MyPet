import 'package:flutter/material.dart';
import '../repositories/user_reviews_repository.dart';

class UserReviewsProvider extends ChangeNotifier {
  final IUserReviewsRepository _repository;

  UserReviewsProvider(this._repository);

  final Set<String> _reviewedBookingIds = {};

  Set<String> get reviewedBookingIds => _reviewedBookingIds;
  bool isReviewed(String bookingId) => _reviewedBookingIds.contains(bookingId);

  Future<void> loadReviewed({required String token}) async {
    try {
      _reviewedBookingIds
          .addAll(await _repository.reviewedBookingIds(token: token));
      notifyListeners();
    } catch (_) {}
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
