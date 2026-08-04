import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:store/repositories/product_repository.dart';
import 'package:store/repositories/cart_repository.dart';
import 'package:store/pages/customer/dashboard.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final productRepository = ProductRepository.instance;
  final cartRepository = CartRepository.instance;

  await Future.wait([
    productRepository.loadProducts(),
    cartRepository.loadCart(),
  ]);

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: productRepository),
        ChangeNotifierProvider.value(value: cartRepository),
      ],
      child: const MyApp(),
    ),
  );
}

// ...

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store',
      home: const CustomerDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
