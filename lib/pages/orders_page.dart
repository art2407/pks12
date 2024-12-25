import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/orders_provider.dart';
import '../model/order.dart';
import '../services/product_service.dart';

class OrdersPage extends StatelessWidget {
  const OrdersPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Provider<ProductService>(
      create: (_) => ProductService(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Мои заказы'),
        ),
        body: Consumer<OrdersProvider>(
          builder: (context, ordersProvider, child) {
            final orders = ordersProvider.orders;

            if (orders.isEmpty) {
              return const Center(
                child: Text(
                  'У вас пока нет заказов',
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ExpansionTile(
                    title: Text('Заказ #${order.id}'),
                    subtitle: Text(
                      'Статус: ${order.status}\nСумма: ${order.totalAmount} ₽',
                    ),
                    children: [
                      ...order.items.map((item) => FutureBuilder(
                        future: Provider.of<ProductService>(context, listen: false).getProductById(item.productId),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            print('Error loading product: ${snapshot.error}');
                            return ListTile(
                              title: Text('Ошибка загрузки товара'),
                              subtitle: Text('ID: ${item.productId}'),
                            );
                          }
                          if (snapshot.hasData) {
                            final product = snapshot.data!;
                            return ListTile(
                              title: Text(product.title),
                              subtitle: Text(
                                'Количество: ${item.quantity}\nЦена: ${item.price} ₽',
                              ),
                            );
                          }
                          return const ListTile(
                            title: Text('Загрузка...'),
                            leading: CircularProgressIndicator(),
                          );
                        },
                      )).toList(),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
