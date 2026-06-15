import '../models/availability.dart';
import '../services/availability_service.dart';

abstract class IEstablishmentHoursRepository {
  Future<ScheduleModel> getSchedule({required String estabId, required String token});
  Future<void> saveSchedule({required String token, required ScheduleModel schedule});
  Future<List<TimeSlotModel>> slots(
      {required String estabId, required String date, required String token});
  Future<void> blockSlot({
    required String token,
    required String estabId,
    required String date,
    required String startTime,
    required String endTime,
  });
  Future<void> unblockSlot({required String token, required String blockId});
}

class EstablishmentHoursRepository implements IEstablishmentHoursRepository {
  @override
  Future<ScheduleModel> getSchedule(
          {required String estabId, required String token}) =>
      AvailabilityService.getSchedule(token: token, estabId: estabId);

  @override
  Future<void> saveSchedule(
          {required String token, required ScheduleModel schedule}) =>
      AvailabilityService.saveSchedule(token: token, schedule: schedule);

  @override
  Future<List<TimeSlotModel>> slots(
          {required String estabId,
          required String date,
          required String token}) =>
      AvailabilityService.getAvailability(
          token: token, estabId: estabId, date: date);

  @override
  Future<void> blockSlot({
    required String token,
    required String estabId,
    required String date,
    required String startTime,
    required String endTime,
  }) =>
      AvailabilityService.blockSlot(
        token: token,
        estabId: estabId,
        date: date,
        startTime: startTime,
        endTime: endTime,
      );

  @override
  Future<void> unblockSlot({required String token, required String blockId}) =>
      AvailabilityService.unblockSlot(token: token, blockId: blockId);
}
