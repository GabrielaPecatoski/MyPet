import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../repositories/complaints_repository.dart';

class ComplaintsProvider extends ChangeNotifier {
  final IComplaintsRepository _repository;

  ComplaintsProvider(this._repository);

  List<ComplaintModel> _complaints = [];
  bool _loading = false;
  String? _error;

  List<ComplaintModel> get complaints => _complaints;
  bool get isLoading => _loading;
  String? get error => _error;

  Future<void> load({required String token}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await _repository.getMine(token: token);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _complaints = list;
    } catch (_) {
      _error = 'Não foi possível carregar suas reclamações.';
      _complaints = [];
    }
    _loading = false;
    notifyListeners();
  }
}
