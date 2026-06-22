import 'address.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? cpf;
  final String role;
  final String? photoPath;
  final List<AddressModel> addresses;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.cpf,
    this.role = 'CLIENTE',
    this.photoPath,
    this.addresses = const [],
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
      addresses: (json['addresses'] as List?)
              ?.map((e) => AddressModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
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
        'addresses': addresses.map((a) => a.toJson()).toList(),
      };

  UserModel copyWith({
    String? name,
    String? email,
    String? phone,
    String? cpf,
    String? photoPath,
    List<AddressModel>? addresses,
  }) =>
      UserModel(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        cpf: cpf ?? this.cpf,
        role: role,
        photoPath: photoPath ?? this.photoPath,
        addresses: addresses ?? this.addresses,
      );
}
