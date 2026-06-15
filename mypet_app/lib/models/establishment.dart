class ServiceModel {
  final String id;
  final String name;
  final double price;
  final bool priceVariable;
  final int durationMinutes;
  final String? description;
  final String categoria;
  final String? imagemUrl;
  final bool ativo;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    this.priceVariable = false,
    required this.durationMinutes,
    this.description,
    this.categoria = 'outros',
    this.imagemUrl,
    this.ativo = true,
  });

  String get priceLabel => priceVariable ? 'Sob consulta' : 'R\$ ${price.toStringAsFixed(2)}';

  bool get isVeterinary => const {
        'consulta_veterinaria',
        'vacinacao',
        'exames',
        'cirurgias',
        'internacao',
        'emergencia',
        'medicamentos',
        'atendimento_domiciliar',
      }.contains(categoria);

  String get categoriaLabel {
    const labels = {
      'banho': 'Banho',
      'tosa': 'Tosa',
      'consulta_veterinaria': 'Consulta Veterinária',
      'vacinacao': 'Vacinação',
      'exames': 'Exames',
      'cirurgias': 'Cirurgias',
      'internacao': 'Internação',
      'emergencia': 'Emergência',
      'medicamentos': 'Medicamentos',
      'atendimento_domiciliar': 'Atendimento Domiciliar',
      'outros': 'Outros',
    };
    return labels[categoria] ?? categoria;
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        priceVariable: json['priceVariable'] as bool? ?? false,
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        description: json['description'] as String?,
        categoria: json['categoria'] as String? ?? 'outros',
        imagemUrl: json['imagemUrl'] as String?,
        ativo: json['ativo'] as bool? ?? true,
      );
}

class EstablishmentModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String type;
  final String address;
  final String rawAddress;
  final String city;
  final String phone;
  final double rating;
  final int reviewCount;
  final int serviceCount;
  final String? imageUrl;
  final List<ServiceModel> services;
  final String? crmv;
  final bool atendeEmergencia;
  final bool atendimento24h;
  final bool receberAlertaSonoro;
  final bool receberPushEmergencia;

  EstablishmentModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    required this.type,
    required this.address,
    required this.rawAddress,
    required this.city,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    this.serviceCount = 0,
    this.imageUrl,
    this.services = const [],
    this.crmv,
    this.atendeEmergencia = false,
    this.atendimento24h = false,
    this.receberAlertaSonoro = false,
    this.receberPushEmergencia = false,
  });

  bool get isVeterinario => type == 'VETERINARIA' || type == 'HIBRIDO';
  bool get isPetShop => type == 'PET_SHOP' || type == 'HIBRIDO';

  String get typeLabel {
    switch (type) {
      case 'PET_SHOP':
        return 'Pet Shop';
      case 'VETERINARIA':
        return 'Clínica Veterinária';
      case 'HIBRIDO':
        return 'Pet Shop + Clínica';
      default:
        return 'Pet Shop';
    }
  }

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List? ?? [])
        .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
        .toList();
    final rawAddress = json['address'] as String? ?? '';
    final rawCity = json['city'] as String? ?? '';
    final addressDisplay = [rawAddress, rawCity]
        .where((s) => s.isNotEmpty)
        .join(' — ');
    return EstablishmentModel(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? '',
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      type: json['type'] as String? ?? 'PET_SHOP',
      address: addressDisplay,
      rawAddress: rawAddress,
      city: rawCity,
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      serviceCount: (json['serviceCount'] as num?)?.toInt() ?? servicesList.length,
      imageUrl: json['imageUrl'] as String?,
      services: servicesList,
      crmv: json['crmv'] as String?,
      atendeEmergencia: json['atendeEmergencia'] as bool? ?? false,
      atendimento24h: json['atendimento24h'] as bool? ?? false,
      receberAlertaSonoro: json['receberAlertaSonoro'] as bool? ?? false,
      receberPushEmergencia: json['receberPushEmergencia'] as bool? ?? false,
    );
  }

  EstablishmentModel copyWith({
    String? name,
    String? description,
    String? type,
    String? rawAddress,
    String? city,
    String? phone,
    String? imageUrl,
    bool clearImage = false,
    List<ServiceModel>? services,
    String? crmv,
    bool? atendeEmergencia,
    bool? atendimento24h,
    bool? receberAlertaSonoro,
    bool? receberPushEmergencia,
  }) {
    final newRawAddress = rawAddress ?? this.rawAddress;
    final newCity = city ?? this.city;
    final newAddress = [newRawAddress, newCity]
        .where((s) => s.isNotEmpty)
        .join(' — ');
    return EstablishmentModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      address: newAddress,
      rawAddress: newRawAddress,
      city: newCity,
      phone: phone ?? this.phone,
      rating: rating,
      reviewCount: reviewCount,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
      services: services ?? this.services,
      crmv: crmv ?? this.crmv,
      atendeEmergencia: atendeEmergencia ?? this.atendeEmergencia,
      atendimento24h: atendimento24h ?? this.atendimento24h,
      receberAlertaSonoro: receberAlertaSonoro ?? this.receberAlertaSonoro,
      receberPushEmergencia: receberPushEmergencia ?? this.receberPushEmergencia,
    );
  }
}
