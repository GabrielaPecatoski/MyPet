import '../models/admin_data.dart';
import '../models/complaint.dart';
import '../services/admin_service.dart';
import '../services/complaint_service.dart';
import '../services/stats_service.dart';

class AdminRepository {
  final String token;

  AdminRepository({required this.token});

  Future<List<AdminUserModel>> getUsers() =>
      AdminService.fetchUsers(token: token);

  Future<void> deleteUser(String userId) =>
      AdminService.deleteUser(userId: userId, token: token);

  Future<List<AdminEstabModel>> getEstablishments() =>
      AdminService.fetchEstablishments(token: token);

  Future<List<ComplaintModel>> getComplaints() =>
      ComplaintService.fetchAll(token: token);

  Future<ComplaintModel> resolveComplaint(String complaintId) =>
      ComplaintService.resolve(complaintId: complaintId, token: token);

  Future<void> removeComplaint(String complaintId) =>
      ComplaintService.remove(complaintId: complaintId, token: token);

  Future<AdminStatsModel> getStats() =>
      StatsService.fetchAdminStats(token: token);
}
