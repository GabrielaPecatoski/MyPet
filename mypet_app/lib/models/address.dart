/// Endereço salvo no perfil do usuário (qualquer conta). As coordenadas
/// (lat/lng) são preenchidas por geocodificação e usadas para serviços
/// próximos e para a rota do transporte.
class AddressModel {
  final String id;
  final String label;
  final String cep;
  final String street;
  final String number;
  final String district;
  final String city;
  final double? lat;
  final double? lng;

  AddressModel({
    required this.id,
    this.label = '',
    this.cep = '',
    this.street = '',
    this.number = '',
    this.district = '',
    this.city = '',
    this.lat,
    this.lng,
  });

  bool get hasCoords => lat != null && lng != null;

  /// Texto de uma linha para geocodificar / exibir.
  String get fullText {
    final parts = [
      [street, number].where((s) => s.isNotEmpty).join(', '),
      district,
      city,
    ].where((s) => s.isNotEmpty).toList();
    return parts.join(' — ');
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) => AddressModel(
        id: json['id'] as String? ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        label: json['label'] as String? ?? '',
        cep: json['cep'] as String? ?? '',
        street: json['street'] as String? ?? '',
        number: json['number'] as String? ?? '',
        district: json['district'] as String? ?? '',
        city: json['city'] as String? ?? '',
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'cep': cep,
        'street': street,
        'number': number,
        'district': district,
        'city': city,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
      };

  AddressModel copyWith({double? lat, double? lng}) => AddressModel(
        id: id,
        label: label,
        cep: cep,
        street: street,
        number: number,
        district: district,
        city: city,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
      );
}
