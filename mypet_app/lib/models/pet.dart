class PetModel {
  final String id;
  final String name;
  final String type; // Cachorro, Gato, Outro
  final String breed;
  final int age;
  final double? weight;
  final String? imageUrl;

  PetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    this.weight,
    this.imageUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Cachorro',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'breed': breed,
        'age': age,
        if (weight != null) 'weight': weight,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  String get typeIcon {
    switch (type) {
      case 'Cachorro':
        return '🐶';
      case 'Gato':
        return '🐱';
      default:
        return '🐾';
    }
  }
}
