import '../models/complaint.dart';
import '../services/complaint_service.dart';

abstract class IComplaintsRepository {
  Future<List<ComplaintModel>> getMine({required String token});
}

class ComplaintsRepository implements IComplaintsRepository {
  @override
  Future<List<ComplaintModel>> getMine({required String token}) =>
      ComplaintService.fetchMine(token: token);
}
