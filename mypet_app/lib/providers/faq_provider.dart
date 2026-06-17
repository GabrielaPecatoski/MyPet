import 'package:flutter/material.dart';
import '../models/faq.dart';
import '../repositories/faq_repository.dart';

class FaqProvider extends ChangeNotifier {
  final IFaqRepository _repository;

  FaqProvider(this._repository);

  List<FaqItem> _faqs = [];
  List<String> _categories = [];
  List<UserQuestion> _myQuestions = [];
  bool _loadingFaq = false;
  bool _loadingQuestions = false;

  List<FaqItem> get faqs => _faqs;
  List<String> get categories => _categories;
  List<UserQuestion> get myQuestions => _myQuestions;
  bool get loadingFaq => _loadingFaq;
  bool get loadingQuestions => _loadingQuestions;

  Future<void> loadFaqs() async {
    _loadingFaq = true;
    notifyListeners();
    try {
      _categories = await _repository.categories();
      _faqs = await _repository.faqs();
    } finally {
      _loadingFaq = false;
      notifyListeners();
    }
  }

  Future<void> loadMyQuestions(String userId, {String? token}) async {
    _loadingQuestions = true;
    notifyListeners();
    try {
      _myQuestions = await _repository.userQuestions(userId, token: token);
    } finally {
      _loadingQuestions = false;
      notifyListeners();
    }
  }

  Future<void> submitQuestion({
    required String question,
    required String userId,
    required String userName,
    String userRole = 'CLIENTE',
    String? token,
  }) async {
    final local = UserQuestion(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userRole: userRole,
      question: question,
      status: 'PENDENTE',
      createdAt: DateTime.now(),
    );
    _myQuestions = [local, ..._myQuestions];
    notifyListeners();

    final saved = await _repository.submit(question: question, token: token);
    if (saved != null) {
      _myQuestions = [
        saved,
        ..._myQuestions.where((q) => q.id != local.id),
      ];
      notifyListeners();
    }
  }
}
