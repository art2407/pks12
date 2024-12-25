import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/product.dart';

class FavoritesProvider with ChangeNotifier {
  Set<Product> _favorites = {};
  static const String _key = 'favorites';
  late SharedPreferences _prefs;
  bool _initialized = false;

  FavoritesProvider() {
    init();
  }

  Future<void> init() async {
    if (_initialized) return;
    await _loadFavorites();
    _initialized = true;
  }

  Set<Product> get favorites => _favorites;

  Future<void> _loadFavorites() async {
    _prefs = await SharedPreferences.getInstance();
    final String? favoritesJson = _prefs.getString(_key);
    if (favoritesJson != null) {
      try {
        final List<dynamic> decodedList = json.decode(favoritesJson);
        _favorites = decodedList.map((item) => Product.fromJson(item)).toSet();
        notifyListeners();
      } catch (e) {
        debugPrint('Error loading favorites: $e');
        _favorites = {};
      }
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final String encodedList = json.encode(
        _favorites.map((product) => product.toJson()).toList(),
      );
      await _prefs.setString(_key, encodedList);
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(Product product) {
    return _favorites.any((p) => p.id == product.id);
  }

  Future<void> toggleFavorite(Product product) async {
    final exists = _favorites.any((p) => p.id == product.id);
    if (exists) {
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      product.isFavorite = true;
      _favorites.add(product);
    }
    notifyListeners();
    await _saveFavorites();
  }
}