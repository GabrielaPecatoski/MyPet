import '../models/availability.dart';
import '../models/establishment.dart';
import '../models/review.dart';
import '../services/availability_service.dart';
import '../services/establishment_service.dart';
import '../services/review_service.dart';

abstract class IEstablishmentDetailRepository {
  Future<List<ServiceModel>> services(String estabId);
  Future<List<ReviewModel>> reviews(String estabId, {String? token});
  Future<ScheduleModel> schedule(String estabId, {required String token});
}

class EstablishmentDetailRepository
    implements IEstablishmentDetailRepository {
  @override
  Future<List<ServiceModel>> services(String estabId) =>
      EstablishmentService.fetchServices(estabId);

  @override
  Future<List<ReviewModel>> reviews(String estabId, {String? token}) =>
      ReviewService.getByEstablishment(estabId, token: token);

  @override
  Future<ScheduleModel> schedule(String estabId, {required String token}) =>
      AvailabilityService.getSchedule(token: token, estabId: estabId);
}
