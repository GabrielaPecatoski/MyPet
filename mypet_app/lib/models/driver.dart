class DriverModel {
  final String id;
  final String? establishmentId;
  final String name;
  final String phone;
  final String cpf;
  final String cnh;
  final String vehicleType;
  final String vehicleModel;
  final String vehiclePlate;
  final String? photoUrl;
  final String status;
  final bool online;

  DriverModel({
    required this.id,
    this.establishmentId,
    required this.name,
    required this.phone,
    required this.cpf,
    required this.cnh,
    required this.vehicleType,
    required this.vehicleModel,
    required this.vehiclePlate,
    this.photoUrl,
    this.status = 'ATIVO',
    this.online = false,
  });

  bool get isAtivo => status == 'ATIVO';
  bool get isPendente => status == 'PENDENTE';
  bool get isRejeitado => status == 'REJEITADO';
  bool get isAssociado => establishmentId != null && establishmentId!.isNotEmpty;
  String get statusLabel {
    switch (status) {
      case 'ATIVO': return 'Ativo';
      case 'INATIVO': return 'Inativo';
      case 'PENDENTE': return 'Aguardando aprovação';
      case 'REJEITADO': return 'Cadastro rejeitado';
      default: return status;
    }
  }

  String get vehicleTypeLabel {
    switch (vehicleType) {
      case 'CARRO': return 'Carro';
      case 'MOTO':  return 'Moto';
      case 'VAN':   return 'Van';
      default:      return vehicleType;
    }
  }

  factory DriverModel.fromJson(Map<String, dynamic> json) => DriverModel(
        id: json['id'] as String,
        establishmentId: json['establishmentId'] as String?,
        name: json['name'] as String,
        phone: json['phone'] as String,
        cpf: json['cpf'] as String,
        cnh: json['cnh'] as String,
        vehicleType: json['vehicleType'] as String,
        vehicleModel: json['vehicleModel'] as String,
        vehiclePlate: json['vehiclePlate'] as String,
        photoUrl: json['photoUrl'] as String?,
        status: json['status'] as String? ?? 'ATIVO',
        online: json['online'] as bool? ?? false,
      );
}
