import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/favorites_provider.dart'; 
import '../widgets/item.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<FavoritesProvider>(
        builder: (context, favoritesProvider, child) {
          final favorites = favoritesProvider.favorites;
          
          if (favorites.isEmpty) {
            return const Center(
              child: Text(
                'В избранном пока ничего нет',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              return ItemCard(product: favorites.elementAt(index));
            },
          );
        },
      ),
    );
  }
}