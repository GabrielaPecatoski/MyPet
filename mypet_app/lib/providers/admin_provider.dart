import 'package:flutter/material.dart';
import '../models/admin_data.dart';
import '../models/complaint.dart';
import '../models/driver.dart';
import '../models/veterinarian.dart';
import '../services/api_service.dart';
import '../services/driver_service.dart';
import '../services/storage_service.dart';
import '../services/veterinarian_service.dart';

class AdminProvider extends ChangeNotifier {

  List<AdminUserModel> _users = [];
  List<AdminEstabModel> _estabs = [];
  List<ComplaintModel> _complaints = [];
  List<dynamic> _faqItems = [];
  List<dynamic> _userQuestions = [];
  Map<String, dynamic> _reviewStats = {};
  List<VeterinarianModel> _pendingVets = [];
  List<DriverModel> _pendingDrivers = [];
  bool _loading = false;
  String? _error;
  String? _token;

  List<AdminUserModel> get users => _users;
  List<AdminEstabModel> get estabs => _estabs;
  List<ComplaintModel> get complaints => _complaints;
  List<dynamic> get faqItems => _faqItems;
  List<dynamic> get userQuestions => _userQuestions;
  Map<String, dynamic> get reviewStats => _reviewStats;
  List<VeterinarianModel> get pendingVets => _pendingVets;
  List<DriverModel> get pendingDrivers => _pendingDrivers;
  bool get loading => _loading;
  String? get error => _error;

  int get pendingComplaints => _complaints.where((c) => c.status == 'PENDENTE').length;
  int get pendingQuestions => _userQuestions.where((q) => (q as Map)['status'] == 'PENDENTE').length;
  int get pendingVerifications => _pendingVets.length + _pendingDrivers.length;

  void setToken(String? token) {
    _token = token;
  }

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([
        _loadUsers(),
        _loadEstabs(),
        _loadComplaints(),
        _loadFaq(),
        _loadReviewStats(),
        _loadUserQuestions(),
        _loadPendingVerifications(),
      ]);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUsers() async {
    final data = await ApiService.get('/users', token: _token);
    final list = data is Map ? (data['data'] as List? ?? []) : (data as List? ?? []);
    _users = list.map((e) => AdminUserModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _loadEstabs() async {
    try {
      final data = await ApiService.get('/establishments/admin/all', token: _token);
      _estabs = (data as List).map((e) => AdminEstabModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      try {
        final data = await ApiService.get('/establishments');
        _estabs = (data as List).map((e) => AdminEstabModel.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
  }

  Future<void> _loadComplaints() async {
    try {
      final data = await ApiService.get('/reviews/admin/complaints', token: _token);
      _complaints = (data as List).map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      _complaints = [];
    }
  }

  Future<void> _loadFaq() async {
    try {
      final data = await ApiService.get('/faq/admin/all', token: _token);
      _faqItems = data as List<dynamic>;
    } catch (_) {
      _faqItems = [];
    }
  }

  Future<void> _loadReviewStats() async {
    try {
      final data = await ApiService.get('/reviews/admin/stats', token: _token);
      _reviewStats = data as Map<String, dynamic>;
    } catch (_) {
      _reviewStats = {};
    }
  }

  Future<void> _loadUserQuestions() async {
    try {
      final data = await ApiService.get('/faq/questions/admin/all', token: _token);
      _userQuestions = data as List<dynamic>;
    } catch (_) {
      _userQuestions = [];
    }
  }

  Future<void> _loadPendingVerifications() async {
    if (_token == null) return;
    try {
      final results = await Future.wait([
        VeterinarianService.fetchPending(token: _token!),
        DriverService.fetchPending(token: _token!),
      ]);
      _pendingVets = results[0] as List<VeterinarianModel>;
      _pendingDrivers = results[1] as List<DriverModel>;
    } catch (_) {}
  }

  Future<void> resolveComplaint(String id) async {
    await ApiService.patch('/reviews/admin/complaints/$id/resolve', {}, token: _token);
    await _loadComplaints();
    notifyListeners();
  }

  Future<void> rejectComplaint(String id) async {
    await ApiService.patch('/reviews/admin/complaints/$id/reject', {}, token: _token);
    await _loadComplaints();
    notifyListeners();
  }

  Future<void> createFaq(String question, String answer, String category, String targetRole) async {
    await ApiService.post('/faq/admin', {
      'question': question, 'answer': answer,
      'category': category, 'targetRole': targetRole,
    }, token: _token);
    await _loadFaq();
    notifyListeners();
  }

  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    await ApiService.put('/faq/admin/$id', data, token: _token);
    await _loadFaq();
    notifyListeners();
  }

  Future<void> deleteFaq(String id) async {
    await ApiService.delete('/faq/admin/$id', token: _token);
    await _loadFaq();
    notifyListeners();
  }

  Future<void> answerQuestion(String id, String answer) async {
    await ApiService.put('/faq/questions/admin/$id/answer', {'answer': answer}, token: _token);
    await _loadUserQuestions();
    notifyListeners();
  }

  Future<void> closeQuestion(String id) async {
    await ApiService.put('/faq/questions/admin/$id/close', {}, token: _token);
    await _loadUserQuestions();
    notifyListeners();
  }

  Future<void> approveVet(String vetId) async {
    if (_token == null) return;
    await VeterinarianService.approve(token: _token!, vetId: vetId);
    await _loadPendingVerifications();
    notifyListeners();
  }

  Future<void> rejectVet(String vetId) async {
    if (_token == null) return;
    await VeterinarianService.reject(token: _token!, vetId: vetId);
    await _loadPendingVerifications();
    notifyListeners();
  }

  Future<void> approveDriver(String driverId) async {
    if (_token == null) return;
    await DriverService.approve(token: _token!, driverId: driverId);
    await _loadPendingVerifications();
    notifyListeners();
  }

  Future<void> rejectDriver(String driverId) async {
    if (_token == null) return;
    await DriverService.reject(token: _token!, driverId: driverId);
    await _loadPendingVerifications();
    notifyListeners();
  }

  Future<String?> cnhPhoto(String cpf) => StorageService.getCnhPhoto(cpf);

  Future<String?> crmvPhoto(String cpf) => StorageService.getCrmvPhoto(cpf);
}
