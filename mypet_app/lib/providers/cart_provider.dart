import 'package:flutter/material.dart';

class CartItem {
  final String id;
  final String name;
  final String brand;
  final double price;
  final String unit;
  int quantity;

  CartItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.price,
    required this.unit,
    required this.quantity,
  });
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.quantity);
  double get total => _items.values.fold(0.0, (s, i) => s + i.price * i.quantity);

  void add(Map<String, dynamic> product) {
    final id = product['id'] as String;
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(
        id: id,
        name: product['name'] ?? '',
        brand: product['brand'] ?? '',
        price: (product['price'] as num).toDouble(),
        unit: product['unit'] ?? '',
        quantity: 1,
      );
    }
    notifyListeners();
  }

  void increment(String id) {
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
      notifyListeners();
    }
  }

  void decrement(String id) {
    if (!_items.containsKey(id)) return;
    if (_items[id]!.quantity <= 1) {
      _items.remove(id);
    } else {
      _items[id]!.quantity--;
    }
    notifyListeners();
  }

  void remove(String id) {
    _items.remove(id);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  int quantityOf(String id) => _items[id]?.quantity ?? 0;
}
