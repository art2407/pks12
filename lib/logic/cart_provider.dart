import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({
    required this.product,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: Product.fromJson(json['product']),
      quantity: json['quantity'],
    );
  }
}

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  static const String _key = 'cart_items';
  late SharedPreferences _prefs;
  bool _initialized = false;

  CartProvider() {
    init();
  }

  Future<void> init() async {
    if (_initialized) return;
    await _loadCart();
    _initialized = true;
  }

  List<CartItem> get items => _items;

  Future<void> _loadCart() async {
    _prefs = await SharedPreferences.getInstance();
    final String? cartJson = _prefs.getString(_key);
    if (cartJson != null) {
      final List<dynamic> decodedList = json.decode(cartJson);
      _items = decodedList.map((item) => CartItem.fromJson(item)).toList();
      notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    final String encodedList = json.encode(
      _items
          .map((item) => {
                'product': item.product.toJson(),
                'quantity': item.quantity,
              })
          .toList(),
    );
    await _prefs.setString(_key, encodedList);
  }

  void addItem(Product product) {
    final existingCartItemIndex = _items.indexWhere(
      (item) => item.product == product,
    );

    if (existingCartItemIndex >= 0) {
      _items[existingCartItemIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }
    _saveCart();
    notifyListeners();
  }

  void removeItem(Product product) {
    _items.removeWhere((item) => item.product == product);
    _saveCart();
    notifyListeners();
  }

  void decrementQuantity(Product product) {
    final existingCartItemIndex = _items.indexWhere(
      (item) => item.product == product,
    );

    if (existingCartItemIndex >= 0) {
      if (_items[existingCartItemIndex].quantity > 1) {
        _items[existingCartItemIndex].quantity--;
      } else {
        _items.removeAt(existingCartItemIndex);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void incrementQuantity(Product product) {
    final existingCartItemIndex = _items.indexWhere(
      (item) => item.product == product,
    );

    if (existingCartItemIndex >= 0) {
      _items[existingCartItemIndex].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  void clear() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  double get totalAmount {
    return _items.fold(
        0.0, (sum, item) => sum + (item.product.price * item.quantity));
  }
}
