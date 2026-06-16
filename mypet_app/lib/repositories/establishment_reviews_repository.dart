import '../models/complaint.dart';
import '../models/review.dart';
import '../services/api_service.dart';
import '../services/complaint_service.dart';
import '../services/review_service.dart';

abstract class IEstablishmentReviewsRepository {
  Future<String?> ownerEstablishmentId(String ownerId, {String? token});
  Future<List<ReviewModel>> reviews(String estabId, {String? token});
  Future<List<ComplaintModel>> complaints(String estabId, {String? token});
}

class EstablishmentReviewsRepository
    implements IEstablishmentReviewsRepository {
  @override
  Future<String?> ownerEstablishmentId(String ownerId, {String? token}) async {
    final data =
        await ApiService.get('/establishments/owner/$ownerId', token: token);
    final estabs = data is List ? data : [data];
    if (estabs.isEmpty) return null;
    return (estabs.first as Map<String, dynamic>)['id'] as String?;
  }

  @override
  Future<List<ReviewModel>> reviews(String estabId, {String? token}) =>
      ReviewService.getByEstablishment(estabId, token: token);

  @override
  Future<List<ComplaintModel>> complaints(String estabId, {String? token}) =>
      ComplaintService.fetchByEstab(estabId: estabId, token: token ?? '');
}
