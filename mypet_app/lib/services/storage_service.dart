import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class StorageService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  static Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_userKey);
    if (json == null) return null;
    return UserModel.fromJson(jsonDecode(json));
  }

  static const _vehiclePhotoKey = 'driver_vehicle_photo';

  static Future<void> saveVehiclePhoto(String? path) async {
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_vehiclePhotoKey);
    } else {
      await prefs.setString(_vehiclePhotoKey, path);
    }
  }

  static Future<String?> getVehiclePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_vehiclePhotoKey);
  }

  static String _crmvPhotoKey(String cpf) => 'vet_crmv_photo_$cpf';

  static Future<void> saveCrmvPhoto(String cpf, String? path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _crmvPhotoKey(cpf);
    if (path == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, path);
    }
  }

  static Future<String?> getCrmvPhoto(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_crmvPhotoKey(cpf));
  }

  static String _cnhPhotoKey(String cpf) => 'driver_cnh_photo_$cpf';

  static Future<void> saveCnhPhoto(String cpf, String? path) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _cnhPhotoKey(cpf);
    if (path == null) {
      await prefs.remove(key);
    } else {
      await prefs.setString(key, path);
    }
  }

  static Future<String?> getCnhPhoto(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_cnhPhotoKey(cpf));
  }

  // ----- Conta bancária / PIX do motorista (persistência local) -----
  static String _pixKeyKey(String cpf) => 'driver_pix_key_$cpf';
  static String _pixTypeKey(String cpf) => 'driver_pix_type_$cpf';

  static Future<void> savePix(
      String cpf, {required String? key, required String type}) async {
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove(_pixKeyKey(cpf));
    } else {
      await prefs.setString(_pixKeyKey(cpf), key);
    }
    await prefs.setString(_pixTypeKey(cpf), type);
  }

  static Future<Map<String, String?>> getPix(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'key': prefs.getString(_pixKeyKey(cpf)),
      'type': prefs.getString(_pixTypeKey(cpf)) ?? 'CPF',
    };
  }

  // ----- Configurações do motorista (notificações/privacidade) -----
  static String _driverSettingsKey(String cpf) => 'driver_settings_$cpf';

  static Future<void> saveDriverSettings(
      String cpf, Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_driverSettingsKey(cpf), jsonEncode(settings));
  }

  static Future<Map<String, bool>> getDriverSettings(String cpf) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_driverSettingsKey(cpf));
    if (raw == null) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map((k, v) => MapEntry(k, v == true));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    await prefs.remove(_vehiclePhotoKey);
  }
}
