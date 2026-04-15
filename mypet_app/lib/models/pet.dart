class PetModel {
  final String id;
  final String name;
  final String type; // Cachorro, Gato, Outro
  final String breed;
  final int age;
  final String? imageUrl;

  PetModel({
    required this.id,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    this.imageUrl,
  });

  factory PetModel.fromJson(Map<String, dynamic> json) {
    return PetModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Cachorro',
      breed: json['breed'] ?? '',
      age: json['age'] ?? 0,
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'breed': breed,
        'age': age,
        'imageUrl': imageUrl,
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
