import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/cart_provider.dart';
import '../logic/auth_provider.dart';
import '../logic/orders_provider.dart';

class CartPage extends StatelessWidget {
  const CartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          final cartItems = cartProvider.items;

          if (cartItems.isEmpty) {
            return const Center(
              child: Text('Корзина пуста'),
            );
          }

          return ListView.builder(
            itemCount: cartItems.length,
            itemBuilder: (ctx, i) {
              final item = cartItems[i];
              return Card(
                margin: const EdgeInsets.all(10),
                child: Dismissible(
                  key: Key(item.product.id.toString()),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) async {
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Подтверждение'),
                        content: const Text(
                            'Вы уверены, что хотите удалить этот товар из корзины?'),
                        actions: <Widget>[
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Отмена'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Удалить'),
                          ),
                        ],
                      ),
                    );
                    return result;
                  },
                  onDismissed: (direction) {
                    cartProvider.removeItem(item.product);
                  },
                  background: Container(
                    color: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    alignment: Alignment.centerRight,
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  child: ListTile(
                    leading: Image.network(
                      item.product.imageUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                    title: Text(item.product.title),
                    subtitle:
                        Text('Цена: ${item.product.price * item.quantity} ₽'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () async {
                            if (item.quantity == 1) {
                              final result = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Предупреждение'),
                                  content: const Text(
                                      'Товар будет удален из корзины. Продолжить?'),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      child: const Text('Отмена'),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      child: const Text('Удалить'),
                                    ),
                                  ],
                                ),
                              );
                              if (result == true) {
                                cartProvider.removeItem(item.product);
                              }
                            } else {
                              cartProvider.decrementQuantity(item.product);
                            }
                          },
                        ),
                        Text('${item.quantity}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {
                            cartProvider.incrementQuantity(item.product);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Итого: ${cartProvider.totalAmount} ₽',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                if (cartProvider.items.isNotEmpty)
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final ordersProvider = Provider.of<OrdersProvider>(context, listen: false);
                        
                        if (authProvider.currentUser == null || !authProvider.isAuthenticated) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Необходимо войти в аккаунт'),
                            ),
                          );
                          return;
                        }

                        final userId = authProvider.currentUser!.id;
                        debugPrint('Creating order for user: $userId');

                        // Show loading indicator
                        if (context.mounted) {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext context) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                          );
                        }

                        await ordersProvider.createOrderFromCart(
                          cartProvider.items,
                          userId,
                        );

                        // Clear cart after successful order
                        cartProvider.clear();

                        // Close loading indicator
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Заказ успешно оформлен'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          
                          Navigator.pushNamed(context, '/orders');
                        }
                      } catch (e) {
                        // Close loading indicator if it's showing
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Ошибка при оформлении заказа: $e'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 4),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Оформить заказ'),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
