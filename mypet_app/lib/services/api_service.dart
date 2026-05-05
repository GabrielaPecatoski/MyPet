import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../core/constants.dart';

class ApiService {
  static const _timeout = Duration(seconds: 6);

  static Future<dynamic> get(String path, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http.get(uri, headers: headers).timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body);
    }
    throw Exception('Erro ${res.statusCode}: ${res.body}');
  }

  static Future<dynamic> post(String path, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http
        .post(uri, headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    }
    throw Exception('Erro ${res.statusCode}: ${res.body}');
  }

  static Future<dynamic> patch(String path, Map<String, dynamic> body, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http
        .patch(uri, headers: headers, body: jsonEncode(body))
        .timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      if (res.body.isEmpty) return {};
      return jsonDecode(res.body);
    }
    throw Exception('Erro ${res.statusCode}: ${res.body}');
  }

  static Future<void> delete(String path, {String? token}) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$path');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final res = await http.delete(uri, headers: headers).timeout(_timeout);
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw Exception('Erro ${res.statusCode}: ${res.body}');
  }

  static bool isNetworkError(Object e) =>
      e is SocketException || e.toString().contains('TimeoutException') || e.toString().contains('SocketException');
}
