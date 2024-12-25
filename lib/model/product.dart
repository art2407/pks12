import 'dart:convert';
import 'dart:typed_data';

class Product {
  final String id;
  final String title;
  final String description;
  final int price;
  final String imageUrl;
  final String season;
  bool isFavorite;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.season,
    this.isFavorite = false,
  });

  // Создание Product из JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    String decodeString(String input) {
      try {
        return utf8.decode(input.runes.toList());
      } catch (e) {
        return input;
      }
    }

    return Product(
      id: json['id'].toString(),
      title: decodeString(json['name'] ?? json['title']),
      description: decodeString(json['description']),
      price: (json['price'] as num).toInt(),
      imageUrl: json['image_url'] ?? json['imageUrl'],
      season: json['season'] ?? '23/24',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  // Преобразование Product в JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'season': season,
      'isFavorite': isFavorite,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}