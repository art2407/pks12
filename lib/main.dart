import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import './logic/products_provider.dart';
import './logic/favorites_provider.dart';
import './logic/cart_provider.dart';
import './logic/auth_provider.dart';
import './logic/orders_provider.dart';
import './services/auth_service.dart';
import './services/product_service.dart';
import './pages/auth/login_page.dart';
import './pages/home_page.dart';
import './pages/favorites_page.dart';
import './pages/cart_page.dart';
import './pages/profile_page.dart';
import './pages/orders_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Hive
  await Hive.initFlutter();

  // Инициализация Supabase
  await Supabase.initialize(
    url: 'https://rvgdrypryfksytkjbthl.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ2Z2RyeXByeWZrc3l0a2pidGhsIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNTIwNzQsImV4cCI6MjA0OTkyODA3NH0.yv04vRQWEsxAwmSsdALGMwf_a_A0b1um9Tzrsy6PrPs',
    authCallbackUrlHostname: 'https://rvgdrypryfksytkjbthl.supabase.co',
    debug: true,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(
          create: (_) {
            final ordersProvider = OrdersProvider(ProductService());
            // Инициализируем локальное хранилище
            ordersProvider.init();
            return ordersProvider;
          },
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color.fromARGB(255, 116, 116, 116)),
        useMaterial3: true,
      ),
      routes: {
        '/login': (context) => const LoginPage(),
        '/orders': (context) => const OrdersPage(),
      },
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          if (authProvider.isInitializing) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return authProvider.isAuthenticated
              ? const MainScreen()
              : const LoginPage();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    FavoritesPage(),
    CartPage(),
    ProfilePage(),
  ];

  final List<String> _titles = [
    'Главная',
    'Избранное',
    'Корзина',
    'Профиль',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home),
            label: 'Главная',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite),
            label: 'Избранное',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_cart),
            label: 'Корзина',
          ),
          NavigationDestination(
            icon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
