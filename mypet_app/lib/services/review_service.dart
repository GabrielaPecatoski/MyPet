import '../models/review.dart';
import 'api_service.dart';

class ReviewService {
  static Future<void> submitReview({
<<<<<<< HEAD
    required String userId,
    required String userName,
    required String establishmentId,
    required String bookingId,
    required int rating,
    String? comment,
    String? token,
  }) async {
    await ApiService.post(
      '/reviews',
      {
        'userId': userId,
        'userName': userName,
        'establishmentId': establishmentId,
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
      },
      token: token,
    );
  }

  static Future<void> submitClientReview({
    required String establishmentId,
    required String establishmentName,
    required String clientId,
    required String clientName,
    required String bookingId,
    required int rating,
    String? comment,
    String? token,
  }) async {
    await ApiService.post(
      '/reviews/client',
      {
        'establishmentId': establishmentId,
        'establishmentName': establishmentName,
        'clientId': clientId,
        'clientName': clientName,
        'bookingId': bookingId,
        'rating': rating,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
=======
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
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
=======

  static Future<List<ReviewModel>> getMyReviews({required String token}) async {
    final data = await ApiService.get('/reviews/user/me', token: token);
    final list = data as List;
    return list.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
  }
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
}
