class AppointmentModel {
  final String id;
  final String petName;
  final String petBreed;
  final int petAge;
  final String serviceName;
  final String establishmentName;
  final String establishmentAddress;
  final DateTime date;
  final String time;
  final String status; // PENDING, CONFIRMED, REJECTED, CANCELLED, COMPLETED
  final double price;

  AppointmentModel({
    required this.id,
    required this.petName,
    required this.petBreed,
    required this.petAge,
    required this.serviceName,
    required this.establishmentName,
    required this.establishmentAddress,
    required this.date,
    required this.time,
    required this.status,
    required this.price,
  });

  String get statusLabel {
    switch (status) {
      case 'PENDING':
        return 'Pendente';
      case 'CONFIRMED':
        return 'Confirmado';
      case 'REJECTED':
        return 'Recusado';
      case 'CANCELLED':
        return 'Cancelado';
      case 'COMPLETED':
        return 'Concluído';
      default:
        return status;
    }
  }
}
