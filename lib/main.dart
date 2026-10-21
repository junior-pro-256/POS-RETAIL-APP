import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'routes.dart';
import 'screens/business_profile_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/customers_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/login_screen.dart';
import 'screens/offline_screen.dart';
import 'screens/payment_screen.dart';
import 'screens/products_screen.dart';
import 'screens/reports_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'services/app_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final state = AppState();
  await state.load();
  runApp(ChangeNotifierProvider.value(value: state, child: const PosApp()));
}

class PosApp extends StatelessWidget {
  const PosApp({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return MaterialApp(
      title: 'POS Retail Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: state.primary,
          primary: state.primary,
        ),
        scaffoldBackgroundColor: const Color.fromARGB(255, 243, 250, 243),
      ),
      initialRoute: Routes.splash,
      routes: {
        Routes.splash: (_) => const SplashScreen(),
        Routes.login: (_) => const LoginScreen(),
        Routes.home: (_) => const HomeScreen(),
        Routes.products: (_) => const ProductsScreen(),
        Routes.checkout: (_) => const CheckoutScreen(),
        Routes.payment: (_) => const PaymentScreen(),
        Routes.inventory: (_) => const InventoryScreen(),
        Routes.customers: (_) => const CustomersScreen(),
        Routes.reports: (_) => const ReportsScreen(),
        Routes.settings: (_) => const SettingsScreen(),
        Routes.offline: (_) => const OfflineScreen(),
        Routes.profile: (_) => const BusinessProfileScreen(),
      },
    );
  }
}
