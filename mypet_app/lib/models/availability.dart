class WorkingDayModel {
  final int dayOfWeek; // 0=Sun, 1=Mon...6=Sat
  final String startTime; // "08:00"
  final String endTime;   // "18:00"
  final bool isOpen;

  const WorkingDayModel({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.isOpen,
  });

  factory WorkingDayModel.fromJson(Map<String, dynamic> j) => WorkingDayModel(
        dayOfWeek: j['dayOfWeek'] as int,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        isOpen: j['isOpen'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'isOpen': isOpen,
      };

  WorkingDayModel copyWith({String? startTime, String? endTime, bool? isOpen}) =>
      WorkingDayModel(
        dayOfWeek: dayOfWeek,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        isOpen: isOpen ?? this.isOpen,
      );
}

class ScheduleModel {
  final String establishmentId;
  final int slotDurationMinutes;
<<<<<<< HEAD
=======
  final int capacity;
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  final List<WorkingDayModel> days;

  const ScheduleModel({
    required this.establishmentId,
    required this.slotDurationMinutes,
<<<<<<< HEAD
=======
    this.capacity = 1,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    required this.days,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> j) => ScheduleModel(
        establishmentId: j['establishmentId'] as String,
<<<<<<< HEAD
        slotDurationMinutes: j['slotDurationMinutes'] as int,
        days: (j['days'] as List)
            .map((d) => WorkingDayModel.fromJson(d))
=======
        slotDurationMinutes: (j['slotDurationMinutes'] as num).toInt(),
        capacity: (j['capacity'] as num?)?.toInt() ?? 1,
        days: (j['days'] as List)
            .map((d) => WorkingDayModel.fromJson(d as Map<String, dynamic>))
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'establishmentId': establishmentId,
        'slotDurationMinutes': slotDurationMinutes,
<<<<<<< HEAD
=======
        'capacity': capacity,
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
        'days': days.map((d) => d.toJson()).toList(),
      };
}

class TimeSlotModel {
  final String time;
  final bool available;
  final String? reason;
  final String? blockId;
  final String? bookingId;

  const TimeSlotModel({
    required this.time,
    required this.available,
    this.reason,
    this.blockId,
    this.bookingId,
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> j) => TimeSlotModel(
        time: j['time'] as String,
        available: j['available'] as bool,
        reason: j['reason'] as String?,
        blockId: j['blockId'] as String?,
        bookingId: j['bookingId'] as String?,
      );
}
