import 'package:flutter/material.dart';
import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/review.dart';
import '../models/veterinarian.dart';
import '../repositories/establishment_detail_repository.dart';
import '../services/veterinarian_service.dart';

class EstablishmentDetailProvider extends ChangeNotifier {
  final IEstablishmentDetailRepository _repository;

  EstablishmentDetailProvider(this._repository);

  List<ServiceModel> _services = [];
  List<ReviewModel> _reviews = [];
  List<VeterinarianModel> _vets = [];
  ScheduleModel? _schedule;
  bool _reviewsLoading = true;

  List<ServiceModel> get services => _services;
  List<ReviewModel> get reviews => _reviews;
  List<VeterinarianModel> get vets => _vets;
  ScheduleModel? get schedule => _schedule;
  bool get reviewsLoading => _reviewsLoading;

  double get liveRating {
    if (_reviews.isEmpty) return 0.0;
    return _reviews.fold<int>(0, (s, r) => s + r.rating) / _reviews.length;
  }

  int get liveReviewCount => _reviews.length;

  Future<void> load(String estabId, {String? token}) async {
    await Future.wait([
      _loadServices(estabId),
      _loadReviews(estabId, token: token),
      if (token != null) _loadSchedule(estabId, token: token),
      if (token != null) _loadVets(estabId, token: token),
    ]);
  }

  Future<void> _loadVets(String estabId, {required String token}) async {
    try {
      final vets = await VeterinarianService.fetchByEstablishment(
          token: token, establishmentId: estabId);
      _vets = vets.where((v) => v.isAtivo).toList();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadServices(String estabId) async {
    try {
      _services = await _repository.services(estabId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadSchedule(String estabId, {required String token}) async {
    try {
      _schedule = await _repository.schedule(estabId, token: token);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _loadReviews(String estabId, {String? token}) async {
    try {
      _reviews = await _repository.reviews(estabId, token: token);
    } catch (_) {
    } finally {
      _reviewsLoading = false;
      notifyListeners();
    }
  }
}
