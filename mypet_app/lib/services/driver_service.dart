import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/driver.dart';

class DriverService {
  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  static Future<DriverModel> register({
    required String token,
    String? establishmentId,
    required String name,
    required String phone,
    required String cpf,
    required String cnh,
    required String vehicleType,
    required String vehicleModel,
    required String vehiclePlate,
    String? photoUrl,
    String? cnhPhotoUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'phone': phone,
      'cpf': cpf,
      'cnh': cnh,
      'vehicleType': vehicleType,
      'vehicleModel': vehicleModel,
      'vehiclePlate': vehiclePlate,
    };
    if (establishmentId != null) body['establishmentId'] = establishmentId;
    if (photoUrl != null && photoUrl.isNotEmpty) body['photoUrl'] = photoUrl;
    if (cnhPhotoUrl != null && cnhPhotoUrl.isNotEmpty) {
      body['cnhPhotoUrl'] = cnhPhotoUrl;
    }

    final res = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (res.statusCode == 200 || res.statusCode == 201) {
      return DriverModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao registrar motorista';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<List<DriverModel>> fetchAll({required String token}) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => DriverModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<List<DriverModel>> fetchByEstablishment({
    required String token,
    required String establishmentId,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/establishment/$establishmentId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => DriverModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<List<DriverModel>> fetchUnassociated({required String token}) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/unassociated'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list.map((e) => DriverModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return [];
  }

  static Future<DriverModel?> findByCpf({
    required String token,
    required String cpf,
  }) async {
    final res = await http
        .get(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/by-cpf?cpf=${Uri.encodeComponent(cpf)}'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      if (body == null) return null;
      return DriverModel.fromJson(body as Map<String, dynamic>);
    }
    return null;
  }

  static Future<DriverModel> associate({
    required String token,
    required String driverId,
    required String establishmentId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/associate/$establishmentId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      return DriverModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao associar motorista';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<void> dissociate({
    required String token,
    required String driverId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/dissociate'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao desassociar motorista');
  }

  static Future<DriverModel> updatePhoto({
    required String token,
    required String driverId,
    required String photoUrl,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/photo'),
          headers: _headers(token),
          body: jsonEncode({'photoUrl': photoUrl}),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return DriverModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    throw Exception('Erro ao atualizar foto do motorista');
  }

  static Future<DriverModel> setOnline({
    required String token,
    required String driverId,
    required bool online,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/online'),
          headers: _headers(token),
          body: jsonEncode({'online': online}),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return DriverModel.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
    }
    String msg = 'Erro ao atualizar disponibilidade';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<void> deactivate({
    required String token,
    required String driverId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/deactivate'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) throw Exception('Erro ao desativar motorista');
  }

  static Future<List<DriverModel>> fetchPending({required String token}) async {
    try {
      final res = await http
          .get(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/admin/pending'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body) as List;
        return list.map((e) => DriverModel.fromJson(e as Map<String, dynamic>)).toList();
      }
      final all = await fetchAll(token: token);
      return all.where((d) => d.status == 'PENDENTE').toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> approve({
    required String token,
    required String driverId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/approve'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao aprovar motorista');
    }
  }

  static Future<void> reject({
    required String token,
    required String driverId,
  }) async {
    final res = await http
        .patch(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.driversEndpoint}/$driverId/reject'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Erro ao rejeitar motorista');
    }
  }
}
