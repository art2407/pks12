import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/auth_provider.dart';
import '../logic/orders_provider.dart'; // Add this line

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    if (user != null) {
      _nameController.text = user.fullName ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateProfile() async {
    if (_formKey.currentState!.validate()) {
      final success = await context.read<AuthProvider>().updateProfile(
            fullName: _nameController.text.trim(),
          );

      if (mounted) {
        if (success) {
          setState(() => _isEditing = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Профиль обновлен')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Ошибка обновления профиля')),
          );
        }
      }
    }
  }

  String _getOrdersText(int count) {
    if (count == 1) {
      return 'заказ';
    } else if (count < 5) {
      return 'заказа';
    } else {
      return 'заказов';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.save : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _updateProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final user = auth.currentUser;
          if (user == null)
            return const Center(child: Text('Пользователь не найден'));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Аватар
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: user.imageUrl != null
                        ? NetworkImage(user.imageUrl!)
                        : null,
                    child: user.imageUrl == null
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  const SizedBox(height: 24),

                  // ФИО
                  _isEditing
                      ? TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'ФИО',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Пожалуйста, введите ФИО';
                            }
                            return null;
                          },
                        )
                      : Text(
                          user.fullName ?? 'Не указано',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                  const SizedBox(height: 16),

                  // Email
                  ListTile(
                    leading: const Icon(Icons.email),
                    title: const Text('Email'),
                    subtitle: Text(user.email),
                  ),

                  const Divider(height: 32),

                  // Заказы
                  ListTile(
                    leading: const Icon(Icons.shopping_bag),
                    title: const Text('Мои заказы'),
                    subtitle: Consumer<OrdersProvider>(
                      builder: (context, ordersProvider, child) {
                        final orderCount = ordersProvider.orders.length;
                        return Text('$orderCount ${_getOrdersText(orderCount)}');
                      },
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, '/orders');
                    },
                  ),

                  // Чат с продавцом
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Чат с продавцом'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(context, '/chat');
                    },
                  ),

                  const Divider(height: 32),

                  // Кнопка выхода
                  ListTile(
                    leading: const Icon(Icons.exit_to_app, color: Colors.red),
                    title: const Text(
                      'Выйти',
                      style: TextStyle(color: Colors.red),
                    ),
                    onTap: () async {
                      await auth.signOut();
                      if (mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login', (route) => false);
                      }
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
