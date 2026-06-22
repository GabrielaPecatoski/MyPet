class AppointmentModel {
  final String id;
  final String userId;
  final String userName;
  final String petId;
  final String petName;
  final String petBreed;
  final int petAge;
  final String? petPhotoUrl;
  final String serviceName;
  final String establishmentId;
  final String establishmentName;
  final String establishmentAddress;
  final DateTime date;
  final String time;
  final String status;
  final double price;
  final bool priceVariable;
  final String paymentStatus;
  final String? paymentMethod;
  final DateTime? expiresAt;
  final String? driverId;
  final String? driverName;
  final String? driverPhotoUrl;
  final List<String> attendancePhotos;

  AppointmentModel({
    required this.id,
    this.userId = '',
    this.userName = '',
    this.petId = '',
    required this.petName,
    this.petBreed = '',
    this.petAge = 0,
    this.petPhotoUrl,
    required this.serviceName,
    this.establishmentId = '',
    required this.establishmentName,
    this.establishmentAddress = '',
    required this.date,
    required this.time,
    required this.status,
    required this.price,
    this.priceVariable = false,
    this.paymentStatus = 'NONE',
    this.paymentMethod,
    this.expiresAt,
    this.driverId,
    this.driverName,
    this.driverPhotoUrl,
    this.attendancePhotos = const [],
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
      petPhotoUrl: json['petPhotoUrl'] as String?,
      serviceName: json['serviceName'] ?? '',
      establishmentId: json['establishmentId'] ?? '',
      establishmentName: json['establishmentName'] ?? '',
      establishmentAddress: json['establishmentAddress'] ?? '',
      date: scheduled,
      time: '$hour:$min',
      status: json['status'] ?? 'PENDENTE',
      price: (json['price'] ?? 0).toDouble(),
      priceVariable: json['priceVariable'] as bool? ?? false,
      paymentStatus: json['paymentStatus'] as String? ?? 'NONE',
      paymentMethod: json['paymentMethod'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.tryParse(json['expiresAt'] as String)
          : null,
      driverId: json['driverId'] as String?,
      driverName: json['driverName'] as String?,
      driverPhotoUrl: json['driverPhotoUrl'] as String?,
      attendancePhotos: (json['attendancePhotos'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
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

  bool get isPago      => paymentStatus == 'AUTHORIZED' || paymentStatus == 'CAPTURED';
  bool get isRetido    => paymentStatus == 'AUTHORIZED';
  bool get isEstornado => paymentStatus == 'REFUNDED';
  bool get isCapturado => paymentStatus == 'CAPTURED';

  bool get isAguardandoPagamento =>
      !priceVariable &&
      !isPago &&
      !isEstornado &&
      status == 'AGUARDANDO_PAGAMENTO';

  String get statusLabel {
    if (isAguardandoPagamento) return 'Aguardando Pagamento';
    switch (effectiveStatus) {
      case 'PENDENTE':   return 'Aguardando confirmação';
      case 'CONFIRMADO': return 'Confirmado';
      case 'A_CAMINHO':  return 'A caminho';
      case 'RECUSADO':   return 'Recusado';
      case 'CANCELADO':  return 'Cancelado';
      case 'CONCLUIDO':  return 'Concluído';
      default:           return effectiveStatus;
    }
  }

  String? get pagamentoLabel {
    if (isEstornado) return 'Valor estornado';
    if (isCapturado) return 'Pagamento concluído';
    if (isRetido) return 'Pagamento retido';
    return null;
  }

  bool get isPendente   => status == 'PENDENTE';
  bool get isConfirmado => effectiveStatus == 'CONFIRMADO';
  bool get isACaminho   => effectiveStatus == 'A_CAMINHO';
  bool get isActive     => isAguardandoPagamento || isPendente || isConfirmado || isACaminho;

  /// Serviço acontecendo "no horário": confirmado/a caminho e o horário marcado
  /// já chegou (da marcação até 4h depois — janela em que o atendimento ocorre).
  bool get emAtendimento {
    if (!(isConfirmado || isACaminho)) return false;
    final now = DateTime.now();
    return now.isAfter(date.subtract(const Duration(minutes: 5))) &&
        now.isBefore(date.add(const Duration(hours: 4)));
  }

  bool get canPay {
    if (isPago) return false;
    if (!isPendente && !isConfirmado && !isACaminho) return false;
    return date.difference(DateTime.now()).inMinutes > 60;
  }

  bool get canCancel {
    if (status == 'AGUARDANDO_PAGAMENTO' || status == 'PENDENTE') return true;
    if (status == 'CONFIRMADO' || status == 'A_CAMINHO') {
      final now = DateTime.now();
      return date.year == now.year &&
          date.month == now.month &&
          date.day == now.day;
    }
    return false;
  }
}
