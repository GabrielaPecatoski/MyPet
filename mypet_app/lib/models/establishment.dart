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
  });

  factory EstablishmentModel.fromJson(Map<String, dynamic> json) {
    final servicesList = (json['services'] as List? ?? [])
        .map((s) => ServiceModel.fromJson(s as Map<String, dynamic>))
        .toList();
<<<<<<< HEAD
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
=======
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
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
      imageUrl: json['imageUrl'] as String?,
      services: servicesList,
    );
  }

<<<<<<< HEAD
=======
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
    );
  }

>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
  String get typeLabel =>
      type == 'PET_SHOP' ? 'Pet Shop' : 'Clínica Veterinária';
}
