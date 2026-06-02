import 'package:flutter/material.dart';
<<<<<<< HEAD
=======
import '../providers/auth_provider.dart';
import '../services/cart_service.dart';
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba

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
<<<<<<< HEAD

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.quantity);
  double get total => _items.values.fold(0.0, (s, i) => s + i.price * i.quantity);

  void add(Map<String, dynamic> product) {
=======
  String? _userId;
  String? _token;
  bool _loading = false;

  List<CartItem> get items => _items.values.toList();
  int get count => _items.values.fold(0, (s, i) => s + i.quantity);
  double get total =>
      _items.values.fold(0.0, (s, i) => s + i.price * i.quantity);
  bool get isLoading => _loading;
  int quantityOf(String id) => _items[id]?.quantity ?? 0;

  void update(AuthProvider auth) {
    if (!auth.isAuthenticated) {
      _userId = null;
      _token = null;
      _items.clear();
      notifyListeners();
      return;
    }
    final newUserId = auth.user?.id;
    if (newUserId != _userId) {
      _userId = newUserId;
      _token = auth.token;
      _loadFromBackend();
    }
  }

  Future<void> _loadFromBackend() async {
    if (_userId == null) return;
    _loading = true;
    notifyListeners();
    try {
      final data = await CartService.getCart(_userId!, token: _token);
      _items.clear();
      for (final item in data) {
        final product = item['product'] as Map<String, dynamic>;
        final id = product['id'] as String;
        _items[id] = CartItem(
          id: id,
          name: product['name'] as String? ?? '',
          brand: product['brand'] as String? ?? '',
          price: (product['price'] as num).toDouble(),
          unit: product['unit'] as String? ?? '',
          quantity: item['quantity'] as int,
        );
      }
    } catch (_) {}
    _loading = false;
    notifyListeners();
  }

  Future<void> reload() => _loadFromBackend();

  Future<void> add(Map<String, dynamic> product) async {
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
    final id = product['id'] as String;
    if (_items.containsKey(id)) {
      _items[id]!.quantity++;
    } else {
      _items[id] = CartItem(
        id: id,
<<<<<<< HEAD
        name: product['name'] ?? '',
        brand: product['brand'] ?? '',
        price: (product['price'] as num).toDouble(),
        unit: product['unit'] ?? '',
=======
        name: product['name'] as String? ?? '',
        brand: product['brand'] as String? ?? '',
        price: (product['price'] as num).toDouble(),
        unit: product['unit'] as String? ?? '',
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
        quantity: 1,
      );
    }
    notifyListeners();
<<<<<<< HEAD
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
=======
    if (_userId != null) {
      try {
        await CartService.addItem(_userId!, id, 1, token: _token);
      } catch (_) {}
    }
  }

  Future<void> addQty(Map<String, dynamic> product, int qty) async {
    final id = product['id'] as String;
    if (_items.containsKey(id)) {
      _items[id]!.quantity += qty;
    } else {
      _items[id] = CartItem(
        id: id,
        name: product['name'] as String? ?? '',
        brand: product['brand'] as String? ?? '',
        price: (product['price'] as num).toDouble(),
        unit: product['unit'] as String? ?? '',
        quantity: qty,
      );
    }
    notifyListeners();
    if (_userId != null) {
      try {
        await CartService.addItem(_userId!, id, qty, token: _token);
      } catch (_) {}
    }
  }

  Future<void> increment(String id) async {
    if (!_items.containsKey(id)) return;
    _items[id]!.quantity++;
    notifyListeners();
    if (_userId != null) {
      try {
        await CartService.updateItem(
            _userId!, id, _items[id]!.quantity, token: _token);
      } catch (_) {}
    }
  }

  Future<void> decrement(String id) async {
    if (!_items.containsKey(id)) return;
    final newQty = _items[id]!.quantity - 1;
    if (newQty <= 0) {
      _items.remove(id);
      notifyListeners();
      if (_userId != null) {
        try {
          await CartService.removeItem(_userId!, id, token: _token);
        } catch (_) {}
      }
    } else {
      _items[id]!.quantity = newQty;
      notifyListeners();
      if (_userId != null) {
        try {
          await CartService.updateItem(_userId!, id, newQty, token: _token);
        } catch (_) {}
      }
    }
  }

  Future<void> remove(String id) async {
    _items.remove(id);
    notifyListeners();
    if (_userId != null) {
      try {
        await CartService.removeItem(_userId!, id, token: _token);
      } catch (_) {}
    }
  }

  Future<void> clear() async {
    _items.clear();
    notifyListeners();
    if (_userId != null) {
      try {
        await CartService.clearCart(_userId!, token: _token);
      } catch (_) {}
    }
  }
>>>>>>> bd8e1bc58e476ec1d93775bbf210b1c3b5438eba
}
