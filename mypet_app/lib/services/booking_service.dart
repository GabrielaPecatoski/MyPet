import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/appointment.dart';
import '../models/establishment.dart';

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
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
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
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<AppointmentModel>> fetchVetBookings({
    required String token,
    required String vetId,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/bookings/vet/$vetId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao buscar agendamentos');
    final list = jsonDecode(res.body) as List;
    return list.map((e) => AppointmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<AppointmentModel> createBooking({
    required String token,
    required String userName,
    required String petId,
    required String petName,
    String petBreed = '',
    int petAge = 0,
    required String serviceName,
    String? establishmentId,
    String? establishmentName,
    String? establishmentAddress,
    required DateTime scheduledAt,
    double price = 0,
    bool priceVariable = false,
    List<ServiceModel>? services,
    String? driverId,
    String? driverName,
    String? driverPhotoUrl,
    String? vetId,
    String? vetName,
  }) async {
    final body = <String, dynamic>{
      'userName': userName,
      'petId': petId,
      'petName': petName,
      if (petBreed.isNotEmpty) 'petBreed': petBreed,
      if (petAge > 0) 'petAge': petAge,
      'serviceName': serviceName,
      'scheduledAt': scheduledAt.toIso8601String(),
      'price': price,
      'priceVariable': priceVariable,
    };
    if (establishmentId != null) body['establishmentId'] = establishmentId;
    if (establishmentName != null) body['establishmentName'] = establishmentName;
    if (establishmentAddress != null && establishmentAddress.isNotEmpty) body['establishmentAddress'] = establishmentAddress;
    if (driverId != null) body['driverId'] = driverId;
    if (driverName != null) body['driverName'] = driverName;
    if (driverPhotoUrl != null) body['driverPhotoUrl'] = driverPhotoUrl;
    if (vetId != null) body['vetId'] = vetId;
    if (vetName != null) body['vetName'] = vetName;
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

    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/bookings'),
          headers: _headers(token),
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
  }

  static Future<AppointmentModel> setAttendancePhotos({
    required String token,
    required String bookingId,
    required List<String> photos,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}/bookings/$bookingId/photos'),
          headers: _headers(token),
          body: jsonEncode({'photos': photos}),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return AppointmentModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao salvar fotos do atendimento';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      msg = data['message'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<AppointmentModel> markAsPaid({
    required String token,
    required String bookingId,
    String method = 'PIX',
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}/bookings/$bookingId/pay'),
          headers: _headers(token),
          body: jsonEncode({'method': method}),
        )
        .timeout(const Duration(seconds: 15));
    final data = jsonDecode(res.body);
    if (res.statusCode == 200) {
      final booking = data['booking'] as Map<String, dynamic>? ?? data;
      return AppointmentModel.fromJson(booking);
    }
    throw Exception(data['message'] ?? 'Erro ao registrar pagamento');
  }
}
