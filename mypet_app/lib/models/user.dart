class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? cpf;
  final String role;
  final String? photoPath;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.cpf,
    this.role = 'CLIENTE',
    this.photoPath,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      cpf: json['cpf'],
      role: json['role'] ?? 'CLIENTE',
      photoPath: json['photoPath'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'phone': phone,
        'cpf': cpf,
        'role': role,
        'photoPath': photoPath,
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? cpf,
    String? photoPath,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        cpf: cpf ?? this.cpf,
        role: role,
        photoPath: photoPath ?? this.photoPath,
      );
}
