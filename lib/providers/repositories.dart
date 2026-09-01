import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/cart_repository.dart';
import '../repositories/interfaces/product_repository.dart';
import '../repositories/product_repository.dart';

final sharedPreferencesProvider = Provider<Future<SharedPreferences>>(
  (ref) => SharedPreferences.getInstance(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(),
);

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final productRepository = ref.watch(productRepositoryProvider);
  return CartRepositoryImpl(productRepository: productRepository);
});

final productRepositoryNotifierProvider =
    AsyncNotifierProvider<ProductRepositoryNotifier, ProductRepository>(
      ProductRepositoryNotifier.new,
    );

class ProductRepositoryNotifier extends AsyncNotifier<ProductRepository> {
  @override
  Future<ProductRepository> build() async {
    final repository = ref.read(productRepositoryProvider);
    await repository.loadProducts();
    return repository;
  }
}

final cartRepositoryNotifierProvider =
    AsyncNotifierProvider<CartRepositoryNotifier, CartRepository>(
      CartRepositoryNotifier.new,
    );

class CartRepositoryNotifier extends AsyncNotifier<CartRepository> {
  @override
  Future<CartRepository> build() async {
    final repository = ref.read(cartRepositoryProvider);
    await repository.loadCart();
    return repository;
  }
}
