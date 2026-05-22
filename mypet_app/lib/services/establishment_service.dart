import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/establishment.dart';

class EstablishmentService {
  static Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  static Future<EstablishmentModel?> fetchByOwner({
    required String token,
    required String ownerId,
  }) async {
    final res = await http
        .get(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/owner/$ownerId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      if (list.isEmpty) return null;
      final estab = list.first as Map<String, dynamic>;
      return _fetchWithServices(token, estab['id'] as String, base: estab);
    }
    throw Exception('Erro ao buscar estabelecimento');
  }

  static Future<EstablishmentModel> create({
    required String token,
    required String ownerId,
    required String name,
    required String phone,
  }) async {
    final res = await http
        .post(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/owner/$ownerId'),
          headers: _headers(token),
          body: jsonEncode({
            'name': name,
            'phone': phone,
            'description': 'Estabelecimento pet',
            'address': 'A definir',
            'city': 'A definir',
            'type': 'PET_SHOP',
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 || res.statusCode == 201) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return _fetchWithServices(token, data['id'] as String, base: data);
    }
    String msg = 'Erro ao criar estabelecimento';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<EstablishmentModel> update({
    required String token,
    required String establishmentId,
    required String name,
    required String description,
    required String address,
    required String city,
    required String phone,
    required String type,
    String? imageUrl,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'phone': phone,
      'type': type,
    };
    if (imageUrl != null) body['imageUrl'] = imageUrl;
    final res = await http
        .patch(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId'),
          headers: _headers(token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));
    if (res.statusCode == 200 || res.statusCode == 204) {
      return _fetchWithServices(token, establishmentId);
    }
    String msg = 'Erro ao atualizar estabelecimento';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      msg = data['message'] as String? ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<void> delete({
    required String token,
    required String establishmentId,
  }) async {
    final res = await http
        .delete(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode != 204 && res.statusCode != 200) {
      String msg = 'Erro ao remover estabelecimento';
      try {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        msg = data['message'] as String? ?? msg;
      } catch (_) {}
      throw Exception(msg);
    }
  }

  static Future<EstablishmentModel> addService({
    required String token,
    required String establishmentId,
    required String name,
    required double price,
    required int durationMinutes,
    String? description,
  }) async {
    final res = await http
        .post(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId/services'),
          headers: _headers(token),
          body: jsonEncode({
            'name': name,
            'price': price,
            'durationMinutes': durationMinutes,
            if (description != null && description.isNotEmpty) 'description': description,
          }),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 || res.statusCode == 201) {
      return _fetchWithServices(token, establishmentId);
    }
    String msg = 'Erro ao adicionar serviço';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<EstablishmentModel> removeService({
    required String token,
    required String establishmentId,
    required String serviceId,
  }) async {
    final res = await http
        .delete(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId/services/$serviceId'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200 || res.statusCode == 204) {
      return _fetchWithServices(token, establishmentId);
    }
    String msg = 'Erro ao remover serviço';
    try {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      final m = data['message'];
      msg = (m is List ? m.join(', ') : m?.toString()) ?? msg;
    } catch (_) {}
    throw Exception(msg);
  }

  static Future<List<ServiceModel>> fetchServices(
    String establishmentId,
  ) async {
    final res = await http
        .get(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId/services'),
        )
        .timeout(const Duration(seconds: 8));
    if (res.statusCode == 200) {
      final list = jsonDecode(res.body) as List;
      return list
          .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
          .toList();
    }
    return [];
  }

  /// Fetches establishment + services and returns a combined model.
  static Future<EstablishmentModel> _fetchWithServices(
    String token,
    String establishmentId, {
    Map<String, dynamic>? base,
  }) async {
    Map<String, dynamic> estabData;
    if (base != null) {
      estabData = base;
    } else {
      final res = await http
          .get(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId'),
            headers: _headers(token),
          )
          .timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) throw Exception('Erro ao buscar estabelecimento');
      estabData = jsonDecode(res.body) as Map<String, dynamic>;
    }

    final svcRes = await http
        .get(
          Uri.parse(
              '${ApiConstants.baseUrl}${ApiConstants.establishmentsEndpoint}/$establishmentId/services'),
          headers: _headers(token),
        )
        .timeout(const Duration(seconds: 8));
    final services = svcRes.statusCode == 200
        ? jsonDecode(svcRes.body) as List
        : [];
    estabData['services'] = services;
    return EstablishmentModel.fromJson(estabData);
  }
}
