class ProductModel {
  final String id;
  final String name;
  final String brand;
  final String category;
  final String unit;
  final String description;
  final String? imageUrl;
  final double price;
  final int stock;
  final bool active;

  ProductModel({
    required this.id,
    required this.name,
    required this.brand,
    required this.category,
    required this.unit,
    required this.description,
    this.imageUrl,
    required this.price,
    required this.stock,
    required this.active,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => ProductModel(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        brand: json['brand'] as String? ?? '',
        category: json['category'] as String? ?? '',
        unit: json['unit'] as String? ?? '',
        description: json['description'] as String? ?? '',
        imageUrl: json['imageUrl'] as String?,
        price: (json['price'] as num?)?.toDouble() ?? 0,
        stock: (json['stock'] as num?)?.toInt() ?? 0,
        active: json['active'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'brand': brand,
        'category': category,
        'unit': unit,
        'description': description,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'price': price,
        'stock': stock,
        'active': active,
      };
}
