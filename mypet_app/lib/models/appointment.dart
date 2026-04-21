class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String petId;
  final String petName;
  final String petBreed;
  final int petAge;
  final String serviceName;
  final String establishmentId;
  final String establishmentName;
  final String establishmentAddress;
  final DateTime date;
  final String time;
  final String status; // PENDENTE, CONFIRMADO, RECUSADO, CANCELADO, CONCLUIDO
  final double price;

  AppointmentModel({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.petId = '',
    required this.petName,
    this.petBreed = '',
    this.petAge = 0,
    required this.serviceName,
    this.establishmentId = '',
    required this.establishmentName,
    this.establishmentAddress = '',
    required this.date,
    required this.time,
    required this.status,
    required this.price,
  });

  factory AppointmentModel.fromJson(Map<String, dynamic> json) {
    final scheduled = DateTime.tryParse(json['scheduledAt'] ?? '') ?? DateTime.now();
    final hour = scheduled.hour.toString().padLeft(2, '0');
    final min = scheduled.minute.toString().padLeft(2, '0');
    return AppointmentModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      petId: json['petId'] ?? '',
      petName: json['petName'] ?? '',
      petBreed: json['petBreed'] ?? '',
      petAge: json['petAge'] ?? 0,
      serviceName: json['serviceName'] ?? '',
      establishmentId: json['establishmentId'] ?? '',
      establishmentName: json['establishmentName'] ?? '',
      establishmentAddress: json['establishmentAddress'] ?? '',
      date: scheduled,
      time: '$hour:$min',
      status: json['status'] ?? 'PENDENTE',
      price: (json['price'] ?? 0).toDouble(),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'PENDENTE':   return 'Pendente';
      case 'CONFIRMADO': return 'Confirmado';
      case 'RECUSADO':   return 'Recusado';
      case 'CANCELADO':  return 'Cancelado';
      case 'CONCLUIDO':  return 'Concluído';
      default:           return status;
    }
  }

  bool get isPendente   => status == 'PENDENTE';
  bool get isConfirmado => status == 'CONFIRMADO';

  bool get canCancel {
    if (status == 'PENDENTE') return true;
    if (status == 'CONFIRMADO') {
      final now = DateTime.now();
      return date.year == now.year && date.month == now.month && date.day == now.day;
    }
    return false;
  }
}
