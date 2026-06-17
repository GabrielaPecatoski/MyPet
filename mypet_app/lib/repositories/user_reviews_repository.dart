import '../services/review_service.dart';

abstract class IUserReviewsRepository {
  Future<Set<String>> reviewedBookingIds({required String token});
  Future<void> submitReview({
    required String establishmentId,
    required String bookingId,
    required int rating,
    String? comment,
    required String token,
  });
}

class UserReviewsRepository implements IUserReviewsRepository {
  @override
  Future<Set<String>> reviewedBookingIds({required String token}) async {
    final reviews = await ReviewService.getMyReviews(token: token);
    return reviews
        .where((r) => r.bookingId.isNotEmpty)
        .map((r) => r.bookingId)
        .toSet();
  }

  @override
  Future<void> submitReview({
    required String establishmentId,
    required String bookingId,
    required int rating,
    String? comment,
    required String token,
  }) =>
      ReviewService.submitReview(
        establishmentId: establishmentId,
        bookingId: bookingId,
        rating: rating,
        comment: comment,
        token: token,
      );
}
