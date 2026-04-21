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

  /// Retorna a rota inicial para o usuário autenticado
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

  Future<bool> login(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await AuthService.login(email: email, password: password);
      _token = data['access_token'];
      _user = UserModel.fromJson(data['user']);
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
      _token = data['access_token'];
      _user = UserModel.fromJson(data['user']);
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
