import '../models/review.dart';
import '../models/complaint.dart';
import '../services/review_service.dart';
import '../services/complaint_service.dart';

class ReviewRepository {
  final String estabId;
  final String token;

  ReviewRepository({required this.estabId, required this.token});

  Future<List<ReviewModel>> getReviews() =>
      ReviewService.getByEstablishment(estabId, token: token);

  Future<List<ComplaintModel>> getComplaints() =>
      ComplaintService.fetchByEstab(estabId: estabId, token: token);

  Future<ComplaintModel> respondComplaint({
    required String complaintId,
    required String response,
  }) =>
      ComplaintService.respond(
        complaintId: complaintId,
        response: response,
        token: token,
      );
}
