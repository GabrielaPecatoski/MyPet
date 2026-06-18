import '../models/availability.dart';
import '../models/driver.dart';
import '../models/establishment.dart';
import '../models/pet.dart';
import '../services/availability_service.dart';
import '../services/driver_service.dart';
import '../services/establishment_service.dart';
import 'pet_repository.dart';

abstract class IScheduleRepository {
  Future<List<PetModel>> pets(String userId, {String? token});
  Future<List<ServiceModel>> services(String estabId);
  Future<List<DriverModel>> activeDrivers(String estabId, {required String token});
  Future<List<TimeSlotModel>> slots(
      {required String estabId, required String date, required String token});
}

class ScheduleRepository implements IScheduleRepository {
  final IPetRepository _petRepository;

  ScheduleRepository({IPetRepository? petRepository})
      : _petRepository = petRepository ?? PetRepository();

  @override
  Future<List<PetModel>> pets(String userId, {String? token}) =>
      _petRepository.getByUser(userId, token: token);

  @override
  Future<List<ServiceModel>> services(String estabId) =>
      EstablishmentService.fetchServices(estabId);

  @override
  Future<List<DriverModel>> activeDrivers(String estabId,
      {required String token}) async {
    final byEstab = await DriverService.fetchByEstablishment(
        token: token, establishmentId: estabId);
    final independent = await DriverService.fetchUnassociated(token: token);
    return [...byEstab, ...independent].where((d) => d.isAtivo).toList();
  }

  @override
  Future<List<TimeSlotModel>> slots(
          {required String estabId,
          required String date,
          required String token}) =>
      AvailabilityService.getAvailability(
          token: token, estabId: estabId, date: date);
}
