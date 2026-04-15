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
}

class EstablishmentModel {
  final String id;
  final String name;
  final String type;
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

  String get typeLabel =>
      type == 'PET_SHOP' ? 'Pet Shop' : 'Clínica Veterinária';
}
