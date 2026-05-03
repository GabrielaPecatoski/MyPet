import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  static Future<List<ReviewModel>> getByEstablishment(
    String estabId, {
    required String token,
  }) async {
    final data = await ApiService.get(
      '/reviews/establishment/$estabId',
      token: token,
    );
    final list = data as List;
    return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ReviewModel> create({
    required String establishmentId,
    required String bookingId,
    required int rating,
    required String comment,
    required String token,
  }) async {
    final data = await ApiService.post(
      '/reviews',
      {
        'establishmentId': establishmentId,
        'bookingId': bookingId,
        'rating': rating,
        'comment': comment,
      },
      token: token,
    );
    return ReviewModel.fromJson(data as Map<String, dynamic>);
  }
}
