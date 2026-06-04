class VeterinarianModel {
  final String id;
  final String? establishmentId;
  final String name;
  final String phone;
  final String cpf;
  final String crmv;
  final String? especialidade;
  final String status;
  final bool atendeDomicilio;
  final bool disponivel;

  VeterinarianModel({
    required this.id,
    this.establishmentId,
    required this.name,
    required this.phone,
    required this.cpf,
    required this.crmv,
    this.especialidade,
    this.status = 'ATIVO',
    this.atendeDomicilio = false,
    this.disponivel = true,
  });

  bool get isAtivo => status == 'ATIVO';
  bool get isPendente => status == 'PENDENTE';
  bool get isAssociado => establishmentId != null && establishmentId!.isNotEmpty;
  String get statusLabel {
    switch (status) {
      case 'ATIVO': return 'Ativo';
      case 'INATIVO': return 'Inativo';
      case 'PENDENTE': return 'Aguardando aprovação';
      default: return status;
    }
  }

  factory VeterinarianModel.fromJson(Map<String, dynamic> json) => VeterinarianModel(
        id: json['id'] as String,
        establishmentId: json['establishmentId'] as String?,
        name: json['name'] as String,
        phone: json['phone'] as String,
        cpf: json['cpf'] as String,
        crmv: json['crmv'] as String,
        especialidade: json['especialidade'] as String?,
        status: json['status'] as String? ?? 'ATIVO',
        atendeDomicilio: json['atendeDomicilio'] as bool? ?? false,
        disponivel: json['disponivel'] as bool? ?? true,
      );

  VeterinarianModel copyWith({
    bool? atendeDomicilio,
    bool? disponivel,
    String? status,
  }) =>
      VeterinarianModel(
        id: id,
        establishmentId: establishmentId,
        name: name,
        phone: phone,
        cpf: cpf,
        crmv: crmv,
        especialidade: especialidade,
        status: status ?? this.status,
        atendeDomicilio: atendeDomicilio ?? this.atendeDomicilio,
        disponivel: disponivel ?? this.disponivel,
      );
}
