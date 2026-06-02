import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/appointment.dart';
<<<<<<< HEAD
=======
import '../models/establishment.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

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
<<<<<<< HEAD
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
=======
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
    return list.map((e) => AppointmentModel.fromJson(e)).toList();
=======
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  }

  static Future<AppointmentModel> createBooking({
    required String token,
<<<<<<< HEAD
    required String userId,
=======
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    required String userName,
    required String petId,
    required String petName,
    required String serviceName,
    required String establishmentId,
    required String establishmentName,
    required DateTime scheduledAt,
    double price = 0,
<<<<<<< HEAD
  }) async {
=======
    List<ServiceModel>? services,
  }) async {
    final body = <String, dynamic>{
      'userName': userName,
      'petId': petId,
      'petName': petName,
      'serviceName': serviceName,
      'establishmentId': establishmentId,
      'establishmentName': establishmentName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'price': price,
    };
    if (services != null && services.isNotEmpty) {
      body['services'] = services
          .map((s) => {
                'id': s.id,
                'name': s.name,
                'price': s.price,
                'durationMinutes': s.durationMinutes,
              })
          .toList();
    }

>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/bookings'),
          headers: _headers(token),
<<<<<<< HEAD
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
=======
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return AppointmentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao criar agendamento';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return AppointmentModel.fromJson(data);
    throw Exception(data['message'] ?? 'Erro ao cancelar agendamento');
=======
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AppointmentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao cancelar agendamento';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      msg = data['message'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
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
<<<<<<< HEAD
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) return AppointmentModel.fromJson(data);
    throw Exception(data['message'] ?? 'Erro ao atualizar agendamento');
=======
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AppointmentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao atualizar agendamento';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      msg = data['message'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  }
}
