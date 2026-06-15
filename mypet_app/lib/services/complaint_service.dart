import '../models/complaint.dart';
import 'api_service.dart';

class ComplaintService {
  static Future<void> create({
    required String establishmentId,
    String? bookingId,
    required String subject,
    required String description,
    String? category,
    required String token,
  }) async {
    await ApiService.post(
      '/reviews/complaints',
      {
        'establishmentId': establishmentId,
        if (bookingId != null && bookingId.isNotEmpty) 'bookingId': bookingId,
        'subject': subject,
        'description': description,
        if (category != null && category.isNotEmpty) 'category': category,
      },
      token: token,
    );
  }

  static Future<List<ComplaintModel>> fetchMine({required String token}) async {
    final data = await ApiService.get('/reviews/complaints/user/me', token: token);
    final list = data as List;
    return list.map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<List<ComplaintModel>> fetchByEstab({
    required String estabId,
    required String token,
  }) async {
    final data = await ApiService.get(
      '/reviews/complaints/establishment/$estabId',
      token: token,
    );
    final list = data as List;
    return list.map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ComplaintModel> respond({
    required String complaintId,
    required String response,
    required String token,
  }) async {
    final data = await ApiService.patch(
      '/reviews/complaints/$complaintId/respond',
      {'response': response},
      token: token,
    );
    return ComplaintModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<List<ComplaintModel>> fetchAll({required String token}) async {
    final data = await ApiService.get('/reviews/admin/complaints', token: token);
    final list = data as List;
    return list.map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<ComplaintModel> resolve({
    required String complaintId,
    required String token,
  }) async {
    final data = await ApiService.patch(
      '/reviews/admin/complaints/$complaintId/resolve',
      {},
      token: token,
    );
    return ComplaintModel.fromJson(data as Map<String, dynamic>);
  }

  static Future<void> remove({
    required String complaintId,
    required String token,
  }) async {
    await ApiService.delete('/reviews/admin/complaints/$complaintId', token: token);
  }
}
