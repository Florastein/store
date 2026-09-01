import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/auth_repository.dart';
import '../repositories/cart_repository.dart';
import '../repositories/interfaces/auth_repository.dart';
import '../repositories/interfaces/cart_repository.dart';
import '../repositories/interfaces/product_repository.dart';
import '../repositories/product_repository.dart';
import '../repositories/otp_repository.dart';
import '../repositories/interfaces/otp_repository.dart';
import '../services/device_fingerprint_service.dart';

const _otpServerUrl = String.fromEnvironment(
  'OTP_SERVER_URL',
  defaultValue: 'https://store-otp-worker.vandalsavage111.workers.dev',
);
const _turnstileToken = String.fromEnvironment('TURNSTILE_TOKEN');

final sharedPreferencesProvider = Provider<Future<SharedPreferences>>(
  (ref) => SharedPreferences.getInstance(),
);

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(),
);

final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(authRepositoryProvider).authStateChanges,
);

final otpRepositoryProvider = Provider<OtpRepository>((ref) {
  final fingerprintService = DeviceFingerprintService(
    preferences: ref.watch(sharedPreferencesProvider),
  );
  return OtpRepositoryImpl(
    baseUrl: Uri.parse(_otpServerUrl),
    turnstileTokenProvider: () async => _turnstileToken,
    deviceFingerprintProvider: fingerprintService.getFingerprint,
  );
});

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
