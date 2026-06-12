import 'package:flutter/material.dart';
import '../repositories/admin_repository.dart';
import '../services/faq_service.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepo;

  AdminProvider(this._adminRepo);

  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _faqItems = [];
  List<Map<String, dynamic>> _userQuestions = [];
  bool _loading = false;
  String? _error;

  List<Map<String, dynamic>> get users => _users;
  List<Map<String, dynamic>> get faqItems => _faqItems;
  List<Map<String, dynamic>> get userQuestions => _userQuestions;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> loadAll() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final results = await Future.wait([
        _adminRepo.getUsers(),
        FaqService.adminGetAll(),
        FaqService.adminGetQuestions(),
      ]);
      _users = (results[0] as List).cast<Map<String, dynamic>>();
      _faqItems = (results[1] as List).cast<Map<String, dynamic>>();
      _userQuestions = (results[2] as List).cast<Map<String, dynamic>>();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> answerQuestion(String id, String answer) async {
    await FaqService.adminAnswerQuestion(id, answer);
    _userQuestions = await FaqService.adminGetQuestions();
    notifyListeners();
  }

  Future<void> closeQuestion(String id) async {
    await FaqService.adminCloseQuestion(id);
    _userQuestions = await FaqService.adminGetQuestions();
    notifyListeners();
  }

  Future<void> createFaq(String question, String answer, String category) async {
    await FaqService.adminCreateFaq(question, answer, category);
    _faqItems = await FaqService.adminGetAll();
    notifyListeners();
  }

  Future<void> updateFaq(String id, Map<String, dynamic> data) async {
    await FaqService.adminUpdateFaq(id, data);
    _faqItems = await FaqService.adminGetAll();
    notifyListeners();
  }

  Future<void> deleteFaq(String id) async {
    await FaqService.adminDeleteFaq(id);
    _faqItems = _faqItems.where((f) => f['id'] != id).toList();
    notifyListeners();
  }
}
