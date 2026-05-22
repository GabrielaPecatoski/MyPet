import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  static Future<void> submitReview({
    required String establishmentId,
    required int rating,
    String? comment,
    String? bookingId,
    String? token,
  }) async {
    await ApiService.post(
      '/reviews/establishment/$establishmentId',
      {
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
      },
      token: token,
    );
  }

  static Future<List<ReviewModel>> getByEstablishment(
    String establishmentId, {
    String? token,
  }) async {
    final data = await ApiService.get(
      '/reviews/establishment/$establishmentId',
      token: token,
    );
    final list = data as List;
    return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ReviewModel>> getMyReviews({required String token}) async {
    final data = await ApiService.get('/reviews/user/me', token: token);
    final list = data as List;
    return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
