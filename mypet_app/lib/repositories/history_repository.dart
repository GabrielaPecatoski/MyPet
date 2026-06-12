import '../models/appointment.dart';
import '../services/api_service.dart';
import '../services/booking_service.dart';

abstract class IHistoryRepository {
  Future<List<AppointmentModel>> getByUser(String userId, {String? token});
  Future<void> markCompleted(String bookingId, {required String token});
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
}
