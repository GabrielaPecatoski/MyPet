import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/availability.dart';

class AvailabilityService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<List<TimeSlotModel>> getAvailability({
    required String token,
    required String estabId,
    required String date,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/availability/$estabId?date=$date'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('HTTP ${res.statusCode}: ${res.body}');
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final list = body['slots'] as List;
    return list.map((s) => TimeSlotModel.fromJson(s as Map<String, dynamic>)).toList();
  }

  static Future<ScheduleModel> getSchedule({
    required String token,
    required String estabId,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}/availability/schedule/$estabId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao buscar horários');
    return ScheduleModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }

  static Future<void> saveSchedule({
    required String token,
    required ScheduleModel schedule,
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/availability/schedule'),
          headers: _headers(token),
          body: jsonEncode(schedule.toJson()),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao salvar horários');
    }
  }

  static Future<void> blockSlot({
    required String token,
    required String estabId,
    required String date,
    required String startTime,
    required String endTime,
    String reason = 'Bloqueado',
  }) async {
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/availability/block'),
          headers: _headers(token),
          body: jsonEncode({
            'establishmentId': estabId,
            'date': date,
            'startTime': startTime,
            'endTime': endTime,
            'reason': reason,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao bloquear horário');
    }
  }

  static Future<void> unblockSlot({
    required String token,
    required String blockId,
  }) async {
    final res = await http
        .delete(
          Uri.parse('${ApiConstants.baseUrl}/availability/block/$blockId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw Exception('Erro ao desbloquear horário');
    }
  }

  static String addMinutes(String time, int minutes) {
    final parts = time.split(':');
    final total = int.parse(parts[0]) * 60 + int.parse(parts[1]) + minutes;
    final h = (total ~/ 60).toString().padLeft(2, '0');
    final m = (total % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
