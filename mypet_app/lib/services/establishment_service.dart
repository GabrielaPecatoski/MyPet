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
      return EstablishmentModel.fromJson(list.first as Map<String, dynamic>);
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
            'description': '',
            'address': '',
            'city': '',
            'type': 'PET_SHOP',
          }),
        )
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 || res.statusCode == 201) {
      return EstablishmentModel.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Erro ao criar estabelecimento');
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
            if (description != null && description.isNotEmpty)
              'description': description,
          }),
        )
        .timeout(const Duration(seconds: 8));
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200 || res.statusCode == 201) {
      return EstablishmentModel.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Erro ao adicionar serviço');
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
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      return EstablishmentModel.fromJson(data);
    }
    throw Exception(data['message'] ?? 'Erro ao remover serviço');
  }
}
