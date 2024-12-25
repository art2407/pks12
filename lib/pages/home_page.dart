import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/products_provider.dart';
import '../model/product.dart';
import 'product_details_page.dart';
import '../logic/favorites_provider.dart';
import '../logic/cart_provider.dart';
import '../widgets/item.dart';
import '../widgets/search_sort_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isInit = false;

  @override
  void didChangeDependencies() {
    if (!_isInit) {
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
      _isInit = true;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductsProvider>(
      builder: (context, productsProvider, child) {
        final products = productsProvider.products;
        final error = productsProvider.error;

        if (error != null) {
          return Center(child: Text(error));
        }

        return Column(
          children: [
            const SearchSortBar(),
            Expanded(
              child: products.isEmpty && productsProvider.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : products.isEmpty
                      ? const Center(child: Text('Товары не найдены'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(10),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 1 / 1.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length,
                          itemBuilder: (ctx, index) {
                            final product = products[index];
                            return ItemCard(product: product);
                          },
                        ),
            ),
          ],
        );
      },
    );
  }
}