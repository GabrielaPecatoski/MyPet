import 'package:flutter/material.dart';
import '../models/complaint.dart';
import '../models/review.dart';
import '../repositories/establishment_reviews_repository.dart';

class EstablishmentReviewsProvider extends ChangeNotifier {
  final IEstablishmentReviewsRepository _repository;

  EstablishmentReviewsProvider(this._repository);

  List<ReviewModel> _reviews = [];
  List<ComplaintModel> _complaints = [];
  bool _loading = true;

  List<ReviewModel> get reviews => List.unmodifiable(_reviews);
  List<ComplaintModel> get complaints => List.unmodifiable(_complaints);
  bool get isLoading => _loading;

  double get mediaNota {
    if (_reviews.isEmpty) return 0;
    final total = _reviews.fold<num>(0, (sum, a) => sum + a.rating);
    return total / _reviews.length;
  }

  Future<void> load(String? ownerId, {String? token}) async {
    if (ownerId == null) {
      _loading = false;
      notifyListeners();
      return;
    }
    _loading = true;
    notifyListeners();
    try {
      final estabId =
          await _repository.ownerEstablishmentId(ownerId, token: token);
      if (estabId != null) {
        final results = await Future.wait([
          _repository.reviews(estabId, token: token),
          _repository.complaints(estabId, token: token),
        ]);
        _reviews = results[0] as List<ReviewModel>;
        _complaints = results[1] as List<ComplaintModel>;
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }
}
