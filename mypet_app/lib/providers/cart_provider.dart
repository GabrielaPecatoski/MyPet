import 'package:flutter/material.dart';
import '../models/product.dart';

class CartItem {
  final ProductModel product;
  int quantity;
  CartItem({required this.product, required this.quantity});
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();

  int get totalItems => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      _items.values.fold(0, (sum, item) => sum + item.product.price * item.quantity);

  int quantityOf(String productId) => _items[productId]?.quantity ?? 0;

  void addQty(Map<String, dynamic> productData, int qty) {
    final id = productData['id'] as String;
    if (_items.containsKey(id)) {
      _items[id]!.quantity += qty;
    } else {
      _items[id] = CartItem(product: ProductModel.fromJson(productData), quantity: qty);
    }
    notifyListeners();
  }

  void updateQuantity(String productId, int qty) {
    if (qty <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.quantity = qty;
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
