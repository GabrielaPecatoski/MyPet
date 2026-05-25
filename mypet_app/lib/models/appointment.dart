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
  final String status;
  final double price;
  final bool pago;

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
    this.pago = false,
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
      pago: json['pago'] as bool? ?? false,
    );
  }

  String get effectiveStatus {
    if (status == 'CONFIRMADO' || status == 'A_CAMINHO') {
      if (DateTime.now().isAfter(date.add(const Duration(hours: 4)))) {
        return 'CONCLUIDO';
      }
    }
    return status;
  }

  String get statusLabel {
    switch (effectiveStatus) {
      case 'PENDENTE':   return 'Pendente';
      case 'CONFIRMADO': return 'Confirmado';
      case 'A_CAMINHO':  return 'A caminho';
      case 'RECUSADO':   return 'Recusado';
      case 'CANCELADO':  return 'Cancelado';
      case 'CONCLUIDO':  return 'Concluído';
      default:           return effectiveStatus;
    }
  }

  bool get isPendente   => status == 'PENDENTE';
  bool get isConfirmado => effectiveStatus == 'CONFIRMADO';
  bool get isACaminho   => effectiveStatus == 'A_CAMINHO';
  bool get isActive     => isPendente || isConfirmado || isACaminho;

  bool get canPay {
    if (pago) return false;
    if (!isPendente && !isConfirmado && !isACaminho) return false;
    return date.difference(DateTime.now()).inMinutes > 60;
  }

  bool get canCancel {
    if (status == 'PENDENTE') return true;
    if (status == 'CONFIRMADO' || status == 'A_CAMINHO') {
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }
    return false;
  }
}
