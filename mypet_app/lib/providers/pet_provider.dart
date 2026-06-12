import 'package:flutter/material.dart';
import '../models/pet.dart';
import '../repositories/pet_repository.dart';

class PetProvider extends ChangeNotifier {
  final IPetRepository _repository;

  PetProvider(this._repository);

  List<PetModel> _pets = [];
  bool _loading = false;

  List<PetModel> get pets => List.unmodifiable(_pets);
  bool get isLoading => _loading;

  Future<void> load(String userId, {String? token}) async {
    _loading = true;
    notifyListeners();
    try {
      _pets = await _repository.getByUser(userId, token: token);
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<PetModel?> create(String userId, Map<String, dynamic> data, {String? token}) async {
    try {
      final pet = await _repository.create(userId, data, token: token);
      _pets = [..._pets, pet];
      notifyListeners();
      return pet;
    } catch (_) {
      return null;
    }
  }

  Future<bool> update(String petId, Map<String, dynamic> data, {String? token}) async {
    try {
      final updated = await _repository.update(petId, data, token: token);
      _pets = [for (final p in _pets) p.id == petId ? updated : p];
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> remove(String petId, {String? token}) async {
    try {
      await _repository.delete(petId, token: token);
      _pets = _pets.where((p) => p.id != petId).toList();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
