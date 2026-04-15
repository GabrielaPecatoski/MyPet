import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';
import '../models/user.dart';

bool _isNetworkError(Object e) {
  if (e is SocketException) return true;
  if (e is http.ClientException) return true;
  final s = e.toString();
  return s.contains('TimeoutException') ||
      s.contains('SocketException') ||
      s.contains('XMLHttpRequest error') ||
      s.contains('Connection refused') ||
      s.contains('errno = 121') ||
      s.contains('errno = 111') ||
      s.contains('errno = 10061');
}

final _mockUsers = [
  UserModel(
    id: 'admin-001',
    name: 'Admin MyPet',
    email: 'admin@mypet.com',
    phone: '(11) 99999-0001',
    role: 'ADMIN',
  ),
  UserModel(
    id: 'cliente-001',
    name: 'João Silva',
    email: 'joao@mypet.com',
    phone: '(11) 99999-9999',
    role: 'CLIENTE',
  ),
  UserModel(
    id: 'vendedor-001',
    name: 'Pet Shop Amor & Carinho',
    email: 'petshop@mypet.com',
    phone: '(11) 3456-7890',
    role: 'VENDEDOR',
  ),
];

final _mockPasswords = {
  'admin@mypet.com': 'admin123',
  'joao@mypet.com': 'cliente123',
  'petshop@mypet.com': 'vendedor123',
};

class AuthService {
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConstants.baseUrl}${ApiConstants.loginEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      throw Exception(data['message'] ?? 'Credenciais inválidas');
    } catch (e) {
      if (_isNetworkError(e)) return _localLogin(email, password);
      rethrow;
    }
  }

  static Map<String, dynamic> _localLogin(String email, String password) {
    final user = _mockUsers.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('Email não encontrado'),
    );
    final expectedPass = _mockPasswords[email];
    if (expectedPass != password) {
      throw Exception('Senha incorreta');
    }
    return {
      'access_token': base64Encode(utf8.encode(
          '{"sub":"${user.id}","email":"${user.email}","role":"${user.role}"}')),
      'user': user.toJson(),
    };
  }

  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String cpf,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse(
                '${ApiConstants.baseUrl}${ApiConstants.registerEndpoint}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name,
              'email': email,
              'password': password,
              'phone': phone,
              'cpf': cpf,
            }),
          )
          .timeout(const Duration(seconds: 4));

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return data;
      }
      throw Exception(data['message'] ?? 'Erro ao criar conta');
    } catch (e) {
      if (_isNetworkError(e)) {
        return _localRegister(name: name, email: email, phone: phone, cpf: cpf);
      }
      rethrow;
    }
  }

  static Map<String, dynamic> _localRegister({
    required String name,
    required String email,
    required String phone,
    required String cpf,
  }) {
    final already = _mockUsers.any((u) => u.email == email);
    if (already) throw Exception('Email já cadastrado');

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      email: email,
      phone: phone,
      cpf: cpf,
      role: 'CLIENTE',
    );
    _mockUsers.add(newUser);
    return {
      'access_token': base64Encode(utf8.encode(
          '{"sub":"${newUser.id}","email":"${newUser.email}","role":"CLIENTE"}')),
      'user': newUser.toJson(),
    };
  }
}
