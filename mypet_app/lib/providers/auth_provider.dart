import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = false;
  String? _error;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  String? get error => _error;
  bool get isAuthenticated => _token != null && _user != null;

  String get role => _user?.role ?? 'CLIENTE';
  bool get isAdmin => role == 'ADMIN';
  bool get isVendedor => role == 'VENDEDOR';
  bool get isCliente => role == 'CLIENTE';

  String get homeRoute {
    switch (role) {
      case 'ADMIN':
        return '/admin';
      case 'VENDEDOR':
        return '/estab-home';
      default:
        return '/home';
    }
  }

  Future<void> loadFromStorage() async {
    _token = await StorageService.getToken();
    _user = await StorageService.getUser();
    notifyListeners();
  }

  Future<bool> validateToken() async {
    if (_token == null) return false;
    try {
      final data = await AuthService.getMe(token: _token!);
      _user = UserModel.fromJson(data);
      await StorageService.saveUser(_user!);
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.login(email: email, password: password);
      _token = data['accessToken'] as String?;
      _user = data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null;
      if (_token == null || _user == null) throw Exception('Resposta inválida do servidor');
      await StorageService.saveToken(_token!);
      await StorageService.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String cpf,
    String role = 'CLIENTE',
    String? businessName,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.register(
        name: name,
        email: email,
        password: password,
        phone: phone,
        cpf: cpf,
        role: role,
        businessName: businessName,
      );
      _token = data['accessToken'] as String?;
      _user = data['user'] != null ? UserModel.fromJson(data['user'] as Map<String, dynamic>) : null;
      if (_token == null || _user == null) throw Exception('Resposta inválida do servidor');
      await StorageService.saveToken(_token!);
      await StorageService.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  void updateUser(UserModel updated) {
    _user = updated;
    StorageService.saveUser(updated);
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String name,
    required String phone,
  }) async {
    if (_user == null || _token == null) return false;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.updateMe(
        token: _token!,
        name: name,
        phone: phone,
      );
      _user = UserModel.fromJson(data);
      await StorageService.saveUser(_user!);
      _loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    if (_user == null || _token == null) return false;
    try {
      await AuthService.deleteMe(token: _token!);
      await logout();
      return true;
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await StorageService.clear();
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
