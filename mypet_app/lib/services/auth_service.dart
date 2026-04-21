import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    final message = data['message'];
    throw Exception(message is List ? message.first : message ?? 'Erro ao fazer login');
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String cpf,
    String role = 'CLIENTE',
    String? businessName,
  }) async {
    final body = {
      'name': name,
      'email': email,
      'password': password,
      'phone': phone,
      'cpf': cpf,
      'role': role,
      if (businessName != null) 'businessName': businessName,
    };
    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode == 200 || response.statusCode == 201) {
      return data;
    }

    final message = data['message'];
    throw Exception(message is List ? message.first : message ?? 'Erro ao criar conta');
  }
}
