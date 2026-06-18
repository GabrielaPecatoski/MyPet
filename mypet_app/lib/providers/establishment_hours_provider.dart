import 'package:flutter/material.dart';
import '../models/availability.dart';
import '../services/availability_service.dart';
import '../repositories/establishment_hours_repository.dart';

class ToggleSlotResult {
  final bool success;
  final bool acted;
  final bool wasBlock;
  final String? errorMessage;
  const ToggleSlotResult(
      {required this.success,
      this.acted = false,
      this.wasBlock = false,
      this.errorMessage});
}

class EstablishmentHoursProvider extends ChangeNotifier {
  final IEstablishmentHoursRepository _repository;

  EstablishmentHoursProvider(this._repository);

  String? _estabId;
  String? _token;

  ScheduleModel? _schedule;
  bool _loadingSchedule = false;
  bool _savingSchedule = false;
  int _slotDuration = 60;
  int _capacity = 1;

  DateTime _selectedDay = DateTime.now();
  List<TimeSlotModel> _slots = [];
  bool _loadingSlots = false;

  ScheduleModel? get schedule => _schedule;
  bool get loadingSchedule => _loadingSchedule;
  bool get savingSchedule => _savingSchedule;
  int get slotDuration => _slotDuration;
  int get capacity => _capacity;
  DateTime get selectedDay => _selectedDay;
  List<TimeSlotModel> get slots => _slots;
  bool get loadingSlots => _loadingSlots;

  void configure({String? estabId, String? token}) {
    _estabId = estabId;
    _token = token;
  }

  ScheduleModel _defaultSchedule(String estabId) => ScheduleModel(
        establishmentId: estabId,
        slotDurationMinutes: 60,
        days: const [
          WorkingDayModel(dayOfWeek: 0, startTime: '08:00', endTime: '12:00', isOpen: false),
          WorkingDayModel(dayOfWeek: 1, startTime: '08:00', endTime: '18:00', isOpen: true),
          WorkingDayModel(dayOfWeek: 2, startTime: '08:00', endTime: '18:00', isOpen: true),
          WorkingDayModel(dayOfWeek: 3, startTime: '08:00', endTime: '18:00', isOpen: true),
          WorkingDayModel(dayOfWeek: 4, startTime: '08:00', endTime: '18:00', isOpen: true),
          WorkingDayModel(dayOfWeek: 5, startTime: '08:00', endTime: '18:00', isOpen: true),
          WorkingDayModel(dayOfWeek: 6, startTime: '08:00', endTime: '14:00', isOpen: true),
        ],
      );

  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> loadSchedule() async {
    _loadingSchedule = true;
    notifyListeners();
    try {
      if (_estabId == null || _token == null) throw Exception('não autenticado');
      final s = await _repository.getSchedule(estabId: _estabId!, token: _token!);
      _schedule = s;
      _slotDuration = s.slotDurationMinutes;
      _capacity = s.capacity;
    } catch (_) {
      _schedule = _defaultSchedule(_estabId ?? 'local');
    } finally {
      _loadingSchedule = false;
      notifyListeners();
    }
  }

  void setSlotDuration(int value) {
    _slotDuration = value;
    notifyListeners();
  }

  void setCapacity(int value) {
    _capacity = value;
    notifyListeners();
  }

  void updateDay(int index, WorkingDayModel updated) {
    if (_schedule == null) return;
    final days = List<WorkingDayModel>.from(_schedule!.days);
    days[index] = updated;
    _schedule = ScheduleModel(
      establishmentId: _schedule!.establishmentId,
      slotDurationMinutes: _slotDuration,
      capacity: _capacity,
      days: days,
    );
    notifyListeners();
  }

  Future<String?> saveSchedule() async {
    final s = _schedule;
    if (_estabId == null || _token == null || s == null) return null;
    _savingSchedule = true;
    notifyListeners();
    String? error;
    try {
      await _repository.saveSchedule(
        token: _token!,
        schedule: ScheduleModel(
          establishmentId: _estabId!,
          slotDurationMinutes: _slotDuration,
          capacity: _capacity,
          days: s.days,
        ),
      );
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _savingSchedule = false;
      notifyListeners();
    }
    return error;
  }

  Future<void> setSelectedDay(DateTime day) async {
    _selectedDay = day;
    notifyListeners();
    await loadSlots();
  }

  Future<void> loadSlots() async {
    if (_estabId == null || _token == null) return;
    _loadingSlots = true;
    notifyListeners();
    try {
      _slots = await _repository.slots(
          estabId: _estabId!, date: _dateKey(_selectedDay), token: _token!);
    } catch (_) {
      _slots = [];
    } finally {
      _loadingSlots = false;
      notifyListeners();
    }
  }

  Future<ToggleSlotResult> toggleSlot(TimeSlotModel slot) async {
    if (_estabId == null || _token == null) {
      return const ToggleSlotResult(success: false);
    }
    try {
      if (!slot.available && slot.blockId != null) {
        await _repository.unblockSlot(token: _token!, blockId: slot.blockId!);
        await loadSlots();
        return const ToggleSlotResult(success: true, acted: true, wasBlock: false);
      } else if (slot.available) {
        await _repository.blockSlot(
          token: _token!,
          estabId: _estabId!,
          date: _dateKey(_selectedDay),
          startTime: slot.time,
          endTime: AvailabilityService.addMinutes(slot.time, _slotDuration),
        );
        await loadSlots();
        return const ToggleSlotResult(success: true, acted: true, wasBlock: true);
      }
      return const ToggleSlotResult(success: true);
    } catch (e) {
      return ToggleSlotResult(
          success: false,
          errorMessage: e.toString().replaceAll('Exception: ', ''));
    }
  }
}
