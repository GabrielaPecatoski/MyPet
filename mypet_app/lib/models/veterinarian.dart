class VeterinarianModel {
  final String id;
  final String? establishmentId;
  final String name;
  final String phone;
  final String cpf;
  final String crmv;
  final String? especialidade;
  final String? photoUrl;
  final double? lat;
  final double? lng;
  final String status;
  final bool atendeDomicilio;
  final bool disponivel;
  final bool atende24h;

  VeterinarianModel({
    required this.id,
    this.establishmentId,
    required this.name,
    required this.phone,
    required this.cpf,
    required this.crmv,
    this.especialidade,
    this.photoUrl,
    this.lat,
    this.lng,
    this.status = 'PENDENTE',
    this.atendeDomicilio = false,
    this.disponivel = false,
    this.atende24h = false,
  });

  bool get isAtivo => status == 'ATIVO';
  bool get isPendente => status == 'PENDENTE';
  bool get isRejeitado => status == 'REJEITADO';
  bool get isAprovado => status == 'ATIVO';
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

  factory VeterinarianModel.fromJson(Map<String, dynamic> json) => VeterinarianModel(
        id: json['id'] as String,
        establishmentId: json['establishmentId'] as String?,
        name: json['name'] as String,
        phone: json['phone'] as String,
        cpf: json['cpf'] as String,
        crmv: json['crmv'] as String,
        especialidade: json['especialidade'] as String?,
        photoUrl: json['photoUrl'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        status: json['status'] as String? ?? 'PENDENTE',
        atendeDomicilio: json['atendeDomicilio'] as bool? ?? false,
        disponivel: json['disponivel'] as bool? ?? false,
        atende24h: json['atende24h'] as bool? ?? false,
      );

  VeterinarianModel copyWith({
    bool? atendeDomicilio,
    bool? disponivel,
    bool? atende24h,
    String? status,
    String? photoUrl,
  }) =>
      VeterinarianModel(
        id: id,
        establishmentId: establishmentId,
        name: name,
        phone: phone,
        cpf: cpf,
        crmv: crmv,
        especialidade: especialidade,
        photoUrl: photoUrl ?? this.photoUrl,
        lat: lat,
        lng: lng,
        status: status ?? this.status,
        atendeDomicilio: atendeDomicilio ?? this.atendeDomicilio,
        disponivel: disponivel ?? this.disponivel,
        atende24h: atende24h ?? this.atende24h,
      );
}
