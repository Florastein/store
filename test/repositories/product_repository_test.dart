import 'dart:convert';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store/models/products_model.dart';
import 'package:store/repositories/product_repository.dart';

class MockCacheManager extends Mock implements CacheManager {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockCacheManager mockCacheManager;
  late ProductRepositoryImpl repository;

  setUp(() {
    mockCacheManager = MockCacheManager();
    SharedPreferences.setMockInitialValues({});
    when(
      () => mockCacheManager.getSingleFile(any()),
    ).thenAnswer((_) async => throw UnimplementedError());
    repository = ProductRepositoryImpl(cacheManager: mockCacheManager);
  });

  group('ProductRepositoryImpl', () {
    test('loadProducts loads default products when no cached data', () async {
      await repository.loadProducts();

      expect(repository.products, isNotEmpty);
      expect(repository.products.length, equals(16));
      expect(repository.isLoading, isFalse);
      expect(repository.error, isNull);
    });

    test('loadProducts loads from cache when available', () async {
      final cachedProducts = [
        const StockItem(
          id: 1,
          name: 'Cached Product',
          quantity: 10,
          image: 'https://example.com/image.png',
          status: StockStatus.normal,
          price: 5,
        ),
      ];

      final jsonString = jsonEncode(
        cachedProducts.map((p) => p.toJson()).toList(),
      );
      SharedPreferences.setMockInitialValues({'products': jsonString});

      await repository.loadProducts();

      expect(repository.products.length, equals(1));
      expect(repository.products.first.name, equals('Cached Product'));
    });

    test('add adds a new product', () async {
      await repository.loadProducts();
      final initialCount = repository.products.length;

      final newProduct = StockItem(
        id: repository.nextId,
        name: 'New Product',
        quantity: 50,
        image: 'https://example.com/new.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.add(newProduct);

      expect(repository.products.length, equals(initialCount + 1));
      expect(repository.products.last.name, equals('New Product'));
    });

    test('updateQuantity updates product quantity and status', () async {
      await repository.loadProducts();
      final product = repository.products.first;
      repository.updateQuantity(product.id, 5);

      final updatedProduct = repository.findById(product.id);
      expect(updatedProduct?.quantity, equals(5));
      expect(updatedProduct?.status, equals(StockStatus.lowStock));
    });

    test('updateQuantity sets outOfStock when quantity is 0', () async {
      await repository.loadProducts();
      final product = repository.products.first;

      repository.updateQuantity(product.id, 0);

      final updatedProduct = repository.findById(product.id);
      expect(updatedProduct?.quantity, equals(0));
      expect(updatedProduct?.status, equals(StockStatus.outOfStock));
    });

    test('remove removes a product', () async {
      await repository.loadProducts();
      final product = repository.products.first;
      final initialCount = repository.products.length;

      repository.remove(product.id);

      expect(repository.products.length, equals(initialCount - 1));
      expect(repository.findById(product.id), isNull);
    });

    test('replace updates an existing product', () async {
      await repository.loadProducts();
      final product = repository.products.first;

      final updated = product.copyWith(name: 'Updated Name', price: 99);
      repository.replace(updated);

      final replacedProduct = repository.findById(product.id);
      expect(replacedProduct?.name, equals('Updated Name'));
      expect(replacedProduct?.price, equals(99.0));
    });

    test('findById returns product when exists', () async {
      await repository.loadProducts();
      final product = repository.products.first;

      final found = repository.findById(product.id);

      expect(found, isNotNull);
      expect(found?.id, equals(product.id));
    });

    test('findById returns null when not exists', () async {
      await repository.loadProducts();

      final found = repository.findById(99999);

      expect(found, isNull);
    });

    test('findByBarcode returns product when exists', () async {
      await repository.loadProducts();
      final product = repository.products.first;

      final found = repository.findByBarcode(product.barcode!);

      expect(found, isNotNull);
      expect(found?.barcode, equals(product.barcode));
    });

    test('nextId returns correct next id', () async {
      await repository.loadProducts();
      final maxId = repository.products
          .map((p) => p.id)
          .reduce((a, b) => a > b ? a : b);

      expect(repository.nextId, equals(maxId + 1));
    });

    test('imageBytesFor returns null for non-cached image', () async {
      await repository.loadProducts();
      final product = repository.products.first;

      final bytes = repository.imageBytesFor(
        product.id,
        'https://different.url/image.png',
      );

      expect(bytes, isNull);
    });
  });
}
