import '../models/appointment.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';
import '../services/complaint_service.dart';
import '../services/review_service.dart';

abstract class IHistoryRepository {
  Future<List<AppointmentModel>> getByUser(String userId, {String? token});
  Future<void> markCompleted(String bookingId, {required String token});
  Future<Set<String>> reviewedBookingIds({required String token});
  Future<void> submitReview({
    required String establishmentId,
    required String bookingId,
    required int rating,
    String? comment,
    required String token,
  });
  Future<Set<String>> complainedBookingIds({required String token});
  Future<void> submitComplaint({
    required String establishmentId,
    required String bookingId,
    required String subject,
    required String description,
    String? category,
    required String token,
  });
}

class HistoryRepository implements IHistoryRepository {
  @override
  Future<List<AppointmentModel>> getByUser(String userId, {String? token}) async {
    final data = await ApiService.get('/bookings/user/$userId', token: token);
    return (data as List)
        .map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> markCompleted(String bookingId, {required String token}) =>
      BookingService.updateStatus(
          token: token, bookingId: bookingId, status: 'CONCLUIDO');

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

  @override
  Future<Set<String>> complainedBookingIds({required String token}) async {
    final complaints = await ComplaintService.fetchMine(token: token);
    return complaints
        .where((c) => (c.bookingId ?? '').isNotEmpty)
        .map((c) => c.bookingId!)
        .toSet();
  }

  @override
  Future<void> submitComplaint({
    required String establishmentId,
    required String bookingId,
    required String subject,
    required String description,
    String? category,
    required String token,
  }) =>
      ComplaintService.create(
        establishmentId: establishmentId,
        bookingId: bookingId,
        subject: subject,
        description: description,
        category: category,
        token: token,
      );
}
