import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import 'api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> getMe({required String token}) =>
      ApiService.get('/auth/me', token: token)
          .then((v) => v as Map<String, dynamic>);

  static Future<Map<String, dynamic>> updateMe({
    required String token,
    required String name,
    required String phone,
    String? photoUrl,
  }) =>
      ApiService.patch(
        '/auth/me',
        {
          'name': name,
          'phone': phone,
          if (photoUrl != null) 'photoUrl': photoUrl,
        },
        token: token,
      )
          .then((v) => v as Map<String, dynamic>);

  static Future<void> deleteMe({required String token}) =>
      ApiService.delete('/auth/me', token: token);


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
