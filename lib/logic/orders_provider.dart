import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/order.dart';
import '../services/product_service.dart';
import '../logic/cart_provider.dart';

class OrdersProvider with ChangeNotifier {
  SharedPreferences? _prefs;
  List<Order> _orders = [];  
  final ProductService _productService;
  static const String _ordersKey = 'orders';

  List<Order> get orders => _orders;  

  OrdersProvider(this._productService);

  // Инициализация хранилища
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await loadOrders();
  }

  // Загрузка заказов из локального хранилища
  Future<void> loadOrders() async {
    try {
      final String? ordersJson = _prefs?.getString(_ordersKey);
      if (ordersJson != null && ordersJson.isNotEmpty) {
        final List<dynamic> ordersList = json.decode(ordersJson);
        _orders = ordersList.map((json) => Order.fromJson(json)).toList();
      } else {
        _orders = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Ошибка при загрузке заказов: $e');
      _orders = [];
      notifyListeners();
    }
  }

  // Сохранение заказов в локальное хранилище
  Future<void> _saveOrders() async {
    try {
      final String ordersJson = json.encode(_orders.map((order) => order.toJson()).toList());
      await _prefs?.setString(_ordersKey, ordersJson);
    } catch (e) {
      debugPrint('Ошибка при сохранении заказов: $e');
    }
  }

  // Создание заказа
  Future<void> createOrderFromCart(List<CartItem> cartItems, String customerId) async {
    try {
      // Подсчет общей суммы
      double totalAmount = 0;
      final orderItems = cartItems.map((item) {
        totalAmount += (item.product.price.toDouble() * item.quantity.toDouble());
        return OrderItem(
          productId: item.product.id,
          quantity: item.quantity,
          price: item.product.price.toDouble(),
        );
      }).toList();

      // Создание объекта заказа
      final order = Order(
        id: DateTime.now().millisecondsSinceEpoch.toString(), // Локальный ID
        customerId: customerId,
        items: orderItems,
        totalAmount: totalAmount,
        status: 'NEW',
        createdAt: DateTime.now().toUtc(),
      );

      // Сохраняем локально
      _orders.add(order);
      await _saveOrders();
      notifyListeners();
      
      // Пытаемся синхронизировать с сервером
      try {
        final createdOrder = await _productService.createOrder(order);
        debugPrint('Заказ успешно синхронизирован с сервером: ${createdOrder.id}');
      } catch (e) {
        debugPrint('Не удалось синхронизировать заказ с сервером: $e');
        // Заказ уже сохранен локально, поэтому не выбрасываем ошибку
      }
    } catch (e) {
      debugPrint('Ошибка при создании локального заказа: $e');
      rethrow;
    }
  }
}
