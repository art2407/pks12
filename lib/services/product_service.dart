import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../model/product.dart';
import '../model/favorite.dart';
import '../model/cart_item.dart';
import '../model/order.dart';

class ProductService {
  static final ProductService _instance = ProductService._internal();
  factory ProductService() => _instance;
  ProductService._internal();

  // Используйте IP-адрес вашего компьютера в локальной сети
  static const String baseUrl = 'http://192.168.56.1:8080/api';

  // Получение всех продуктов
  Future<List<Product>> getProducts() async {
    final response = await http.get(Uri.parse('$baseUrl/products'));
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(utf8.decode(response.bodyBytes));
      return jsonList.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load products');
    }
  }

  // Получение продукта по ID
  Future<Product> getProductById(String id) async {
    debugPrint('Fetching product with ID: $id');
    
    // Получаем все продукты и ищем нужный по ID
    try {
      final products = await getProducts();
      final product = products.firstWhere(
        (p) => p.id.toLowerCase() == id.toLowerCase(),
        orElse: () => throw Exception('Product not found'),
      );
      return product;
    } catch (e, stackTrace) {
      debugPrint('Error fetching product: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Работа с избранным
  Future<List<Favorite>> getFavorites(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/favorites?customer_id=$customerId'),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Favorite.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load favorites');
    }
  }

  Future<Favorite> addToFavorites(String customerId, String productId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/favorites'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': customerId,
        'product_id': productId,
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      return Favorite.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add to favorites');
    }
  }

  // Работа с корзиной
  Future<List<CartItem>> getCart(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/cart?customer_id=$customerId'),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => CartItem.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load cart');
    }
  }

  Future<CartItem> addToCart(
      String customerId, String productId, int quantity) async {
    final response = await http.post(
      Uri.parse('$baseUrl/cart'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'customer_id': customerId,
        'product_id': productId,
        'quantity': quantity,
      }),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      return CartItem.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to add to cart');
    }
  }

  // Работа с заказами
  Future<List<Order>> getOrders(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/orders?customer_id=$customerId'),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }

  Future<Order> createOrder(Order order) async {
    try {
      final orderJson = order.toJson();
      debugPrint('Creating order with payload: ${json.encode(orderJson)}');
      debugPrint('Customer ID: ${order.customerId}');
      debugPrint('Items count: ${order.items.length}');
      debugPrint('Total amount: ${order.totalAmount}');
      debugPrint('Status: ${order.status}');
      debugPrint('Created at: ${order.createdAt}');
      
      final requestBody = json.encode(orderJson);
      debugPrint('Request URL: $baseUrl/orders');
      debugPrint('Request headers: ${json.encode({
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      })}');
      debugPrint('Request body:');
      debugPrint(requestBody);

      final response = await http.post(
        Uri.parse('$baseUrl/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      debugPrint('=== Server Response ===');
      debugPrint('Status code: ${response.statusCode}');
      debugPrint('Headers: ${response.headers}');
      final responseText = utf8.decode(response.bodyBytes);
      debugPrint('Body: $responseText');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(responseText);
        debugPrint('Decoded response: $responseData');
        return Order.fromJson(responseData);
      } else {
        debugPrint('!!! Error Response !!!');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Body: $responseText');
        throw Exception('Failed to create order: $responseText');
      }
    } catch (e, stackTrace) {
      debugPrint('!!! Exception !!!');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<Product> updateProduct(Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update product');
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(product.toJson()),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    if (response.statusCode == 200 || response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create product');
    }
  }

  Future<bool> deleteProduct(String id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products?id=$id'),
    );
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    return response.statusCode == 200;
  }
}
