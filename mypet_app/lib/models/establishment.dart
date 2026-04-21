class ServiceModel {
  final String id;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;

  ServiceModel({
    required this.id,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) => ServiceModel(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        durationMinutes: (json['durationMinutes'] as num).toInt(),
        description: json['description'] as String?,
      );
}

class EstablishmentModel {
  final String id;
  final String name;
  final String type; // PET_SHOP, VET_CLINIC
  final String address;
  final String phone;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final List<ServiceModel> services;

  EstablishmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.phone,
    required this.rating,
    required this.reviewCount,
    this.imageUrl,
    this.services = const [],
  });

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List? ?? [])
        .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
        .toList();
    final address = [
      json['address'] as String? ?? '',
      if ((json['city'] as String?)?.isNotEmpty == true) json['city'] as String,
    ].where((s) => s.isNotEmpty).join(' — ');
    return EstablishmentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'PET_SHOP',
      address: address,
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 0,
      imageUrl: json['imageUrl'] as String?,
      services: servicesList,
    );
  }

  String get typeLabel =>
      type == 'PET_SHOP' ? 'Pet Shop' : 'Clínica Veterinária';
}
