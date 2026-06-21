import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/driver_service.dart';
import '../services/storage_service.dart';
import '../services/veterinarian_service.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _user;
  String? _token;
  bool _loading = false;
  String? _error;
  String? _infoMessage;

  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _loading;
  String? get error => _error;
  String? get infoMessage => _infoMessage;
  bool get isAuthenticated => _token != null && _user != null;

  String get role => _user?.role ?? 'CLIENTE';
  bool get isAdmin => role == 'ADMIN';
  bool get isVendedor => role == 'VENDEDOR';
  bool get isCliente => role == 'CLIENTE';
  bool get isMotorista => role == 'MOTORISTA';
  bool get isVeterinario => role == 'VETERINARIO';

  String get homeRoute {
    switch (role) {
      case 'ADMIN':
        return '/admin';
      case 'VENDEDOR':
        return '/estab-home';
      case 'MOTORISTA':
        return '/driver-nav';
      case 'VETERINARIO':
        return '/vet-home';
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

  /// Solicita o envio do e-mail de recuperação. Retorna true em sucesso e
  /// expõe a mensagem genérica do servidor em [infoMessage].
  Future<bool> requestPasswordReset(String email) async {
    _loading = true;
    _error = null;
    _infoMessage = null;
    notifyListeners();
    try {
      _infoMessage = await AuthService.requestPasswordReset(email: email.trim());
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

  /// Redefine a senha a partir do token recebido por e-mail.
  Future<bool> resetPassword(String token, String password) async {
    _loading = true;
    _error = null;
    _infoMessage = null;
    notifyListeners();
    try {
      _infoMessage = await AuthService.resetPassword(
        token: token.trim(),
        password: password,
      );
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

  Future<String?> registerDriverProfile({
    required String name,
    required String phone,
    required String cpf,
    required String cnh,
    required String vehicleType,
    required String vehicleModel,
    required String vehiclePlate,
  }) async {
    if (_token == null) return 'Token ausente';
    try {
      await DriverService.register(
        token: _token!,
        name: name, phone: phone, cpf: cpf,
        cnh: cnh, vehicleType: vehicleType,
        vehicleModel: vehicleModel, vehiclePlate: vehiclePlate,
      );
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  Future<String?> registerVetProfile({
    required String name,
    required String phone,
    required String cpf,
    required String crmv,
    String? especialidade,
    String? crmvPhotoPath,
  }) async {
    if (_token == null) return 'Token ausente';
    if (crmvPhotoPath != null) {
      await StorageService.saveCrmvPhoto(cpf, crmvPhotoPath);
    }
    try {
      await VeterinarianService.register(
        token: _token!,
        name: name, phone: phone, cpf: cpf,
        crmv: crmv, especialidade: especialidade,
      );
      return null;
    } catch (e) {
      return e.toString().replaceAll('Exception: ', '');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
