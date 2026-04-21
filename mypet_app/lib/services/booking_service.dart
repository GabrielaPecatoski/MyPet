import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/appointment.dart';

class BookingService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<AppointmentModel>> fetchUserBookings({
    required String token,
    required String userId,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/bookings/user/$userId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao buscar agendamentos');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  static Future<List<AppointmentModel>> fetchEstabBookings({
    required String token,
    required String estabId,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/bookings/establishment/$estabId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao buscar agendamentos');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
  }

  static Future<AppointmentModel> createBooking({
    required String token,
    required String userId,
    required String userName,
    required String petId,
    required String petName,
    required String serviceName,
    required String establishmentId,
    required String establishmentName,
    required DateTime scheduledAt,
    double price = 0,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/bookings'),
          headers: _headers(token),
          body: jsonEncode({
            'userId': userId,
            'userName': userName,
            'petId': petId,
            'petName': petName,
            'serviceName': serviceName,
            'establishmentId': establishmentId,
            'establishmentName': establishmentName,
            'scheduledAt': scheduledAt.toIso8601String(),
            'price': price,
          }),
        )
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AppointmentModel.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Erro ao criar agendamento');
  }

  static Future<AppointmentModel> cancelBooking({
    required String token,
    required String bookingId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}/bookings/$bookingId/cancel'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return AppointmentModel.fromJson(data);
    throw Exception(data['message'] ?? 'Erro ao cancelar agendamento');
  }

  static Future<AppointmentModel> updateStatus({
    required String token,
    required String bookingId,
    required String status,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}/bookings/$bookingId/status'),
          headers: _headers(token),
          body: jsonEncode({'status': status}),
        )
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return AppointmentModel.fromJson(data);
    throw Exception(data['message'] ?? 'Erro ao atualizar agendamento');
  }
}
