import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../logic/products_provider.dart';

class SearchSortBar extends StatefulWidget {
  const SearchSortBar({super.key});

  @override
  State<SearchSortBar> createState() => _SearchSortBarState();
}

class _SearchSortBarState extends State<SearchSortBar> {
  final TextEditingController _searchController = TextEditingController();
  RangeValues _currentPriceRange = const RangeValues(0, 15000);
  final List<String> _seasons = ['24/25', '23/24', '22/23', '21/22'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showFilterDialog(BuildContext context, ProductsProvider productsProvider) {
    String? selectedSeason = productsProvider.selectedSeason;
    RangeValues priceRange = _currentPriceRange;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Фильтры'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Сезон:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Все'),
                        selected: selectedSeason == null,
                        onSelected: (bool selected) {
                          setState(() {
                            selectedSeason = selected ? null : selectedSeason;
                          });
                        },
                      ),
                      ..._seasons.map((season) => FilterChip(
                        label: Text(season),
                        selected: selectedSeason == season,
                        onSelected: (bool selected) {
                          setState(() {
                            selectedSeason = selected ? season : null;
                          });
                        },
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Цена:', style: TextStyle(fontWeight: FontWeight.bold)),
                  RangeSlider(
                    values: priceRange,
                    min: 0,
                    max: 15000,
                    divisions: 30,
                    labels: RangeLabels(
                      '${priceRange.start.round()}₽',
                      '${priceRange.end.round()}₽',
                    ),
                    onChanged: (RangeValues values) {
                      setState(() {
                        priceRange = values;
                      });
                    },
                  ),
                  Center(
                    child: Text(
                      'От ${priceRange.start.round()}₽ до ${priceRange.end.round()}₽',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Сбросить'),
                  onPressed: () {
                    setState(() {
                      selectedSeason = null;
                      priceRange = const RangeValues(0, 15000);
                    });
                  },
                ),
                TextButton(
                  child: const Text('Отмена'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Применить'),
                  onPressed: () {
                    _currentPriceRange = priceRange;
                    productsProvider.setSelectedSeason(selectedSeason);
                    productsProvider.setPriceRange(
                      priceRange.start,
                      priceRange.end,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productsProvider = Provider.of<ProductsProvider>(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
          child: Row(
            children: [
              // Строка поиска
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Поиск...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: productsProvider.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                productsProvider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(width: 1),
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (value) {
                      productsProvider.setSearchQuery(value);
                    },
                  ),
                ),
              ),
              // Кнопка фильтров
              const SizedBox(width: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: IconButton(
                  icon: Stack(
                    children: [
                      const Icon(Icons.filter_list, size: 20),
                      if (productsProvider.selectedSeason != null ||
                          productsProvider.minPrice > 0 ||
                          productsProvider.maxPrice < double.infinity)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 8,
                              minHeight: 8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _showFilterDialog(context, productsProvider),
                ),
              ),
              // Кнопка сортировки
              const SizedBox(width: 8),
              Container(
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: PopupMenuButton<SortOrder>(
                  icon: const Icon(Icons.sort, size: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  position: PopupMenuPosition.under,
                  onSelected: (SortOrder order) {
                    productsProvider.setSortOrder(order);
                  },
                  itemBuilder: (BuildContext context) => [
                    const PopupMenuItem(
                      value: SortOrder.none,
                      child: Text('Без сортировки'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: SortOrder.nameAscending,
                      child: Text('По названию: А-Я'),
                    ),
                    const PopupMenuItem(
                      value: SortOrder.nameDescending,
                      child: Text('По названию: Я-А'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: SortOrder.priceAscending,
                      child: Text('Цена: по возрастанию'),
                    ),
                    const PopupMenuItem(
                      value: SortOrder.priceDescending,
                      child: Text('Цена: по убыванию'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // Показываем активные фильтры
        if (productsProvider.selectedSeason != null ||
            productsProvider.minPrice > 0 ||
            productsProvider.maxPrice < double.infinity)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Wrap(
              spacing: 8,
              children: [
                if (productsProvider.selectedSeason != null)
                  Chip(
                    label: Text('Сезон: ${productsProvider.selectedSeason}'),
                    onDeleted: () {
                      productsProvider.setSelectedSeason(null);
                    },
                  ),
                if (productsProvider.minPrice > 0 ||
                    productsProvider.maxPrice < double.infinity)
                  Chip(
                    label: Text(
                        'Цена: ${productsProvider.minPrice.round()}₽ - ${productsProvider.maxPrice.round()}₽'),
                    onDeleted: () {
                      setState(() {
                        _currentPriceRange = const RangeValues(0, 15000);
                      });
                      productsProvider.setPriceRange(0, double.infinity);
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}