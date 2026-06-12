import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/emergency_call.dart';
import '../models/veterinarian.dart';

class VeterinarianService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<VeterinarianModel> register({
    required String token,
    String? establishmentId,
    required String name,
    required String phone,
    required String cpf,
    required String crmv,
    String? especialidade,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'cpf': cpf,
      'crmv': crmv,
    };
    if (establishmentId != null) body['establishmentId'] = establishmentId;
    if (especialidade != null && especialidade.isNotEmpty) body['especialidade'] = especialidade;

    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return VeterinarianModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao registrar veterinário';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<List<VeterinarianModel>> fetchByEstablishment({
    required String token,
    required String establishmentId,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/establishment/$establishmentId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => VeterinarianModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<VeterinarianModel?> findByCpf({
    required String token,
    required String cpf,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/by-cpf?cpf=${Uri.encodeComponent(cpf)}'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body == null) return null;
      return VeterinarianModel.fromJson(body as Map<String, dynamic>);
    }
    return null;
  }

  static Future<VeterinarianModel> associate({
    required String token,
    required String vetId,
    required String establishmentId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/associate/$establishmentId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      return VeterinarianModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao associar veterinário';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<void> dissociate({
    required String token,
    required String vetId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/dissociate'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao remover veterinário');
  }

  static Future<List<VeterinarianModel>> fetchAll({required String token}) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => VeterinarianModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<List<VeterinarianModel>> fetchAvailable({required String token}) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/available'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => VeterinarianModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      final all = await fetchAll(token: token);
      return all.where((v) => v.isAtivo).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<VeterinarianModel>> fetchPending({required String token}) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/admin/pending'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => VeterinarianModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      final all = await fetchAll(token: token);
      return all.where((v) => v.status == 'PENDENTE').toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> approve({
    required String token,
    required String vetId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/approve'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao aprovar veterinário');
    }
  }


  static Future<EmergencyCallModel> callVet({
    required String token,
    required String vetId,
    required String callerName,
    required String callerPhone,
    String? petDescription,
  }) async {
    final body = <String, dynamic>{
      'callerName': callerName,
      'callerPhone': callerPhone,
    };
    if (petDescription != null && petDescription.isNotEmpty) {
      body['petDescription'] = petDescription;
    }
    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/emergency-call'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return EmergencyCallModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao enviar chamado de emergência');
  }

  static Future<List<EmergencyCallModel>> getPendingEmergencyCalls({
    required String token,
    required String vetId,
  }) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/emergency-calls/pending'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 6));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => EmergencyCallModel.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {}
    return [];
  }

  static Future<void> acknowledgeEmergencyCall({
    required String token,
    required String callId,
  }) async {
    try {
      await http
          .patch(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/emergency-calls/$callId/acknowledge'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 6));
    } catch (_) {}
  }


  static Future<void> reject({
    required String token,
    required String vetId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/reject'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao rejeitar veterinário');
    }
  }

  static Future<VeterinarianModel> updateAvailability({
    required String token,
    required String vetId,
    bool? disponivel,
    bool? atendeDomicilio,
    bool? atende24h,
  }) async {
    final body = <String, dynamic>{};
    if (disponivel != null) body['disponivel'] = disponivel;
    if (atendeDomicilio != null) body['atendeDomicilio'] = atendeDomicilio;
    if (atende24h != null) body['atende24h'] = atende24h;
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.veterinariansEndpoint}/$vetId/availability'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return VeterinarianModel.fromJson(
          jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao atualizar disponibilidade';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }
}
