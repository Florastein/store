import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store/models/products_model.dart';
import 'package:store/repositories/cart_repository.dart';
import 'package:store/repositories/interfaces/cart_repository.dart';
import 'package:store/repositories/interfaces/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

void main() {
  late MockProductRepository mockProductRepository;
  late CartRepositoryImpl repository;

  setUp(() {
    mockProductRepository = MockProductRepository();
    SharedPreferences.setMockInitialValues({});
    repository = CartRepositoryImpl(productRepository: mockProductRepository);
  });

  group('CartRepositoryImpl', () {
    test('loadCart loads empty cart when no cached data', () async {
      await repository.loadCart();

      expect(repository.items, isEmpty);
      expect(repository.isLoading, isFalse);
      expect(repository.error, isNull);
    });

    test('loadCart loads from cache when available', () async {
      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      final cartItem = CartItem(product: product, quantity: 3);
      final jsonString = jsonEncode([cartItem.toJson()]);
      SharedPreferences.setMockInitialValues({'cart': jsonString});

      await repository.loadCart();

      expect(repository.items.length, equals(1));
      expect(repository.items.first.quantity, equals(3));
      expect(repository.items.first.product.name, equals('Test Product'));
    });

    test('addItem adds new item to empty cart', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.addItem(product, 2);

      expect(repository.items.length, equals(1));
      expect(repository.items.first.quantity, equals(2));
      expect(repository.totalItems, equals(2));
      expect(repository.totalPrice, equals(20.0));
    });

    test('addItem increases quantity for existing item', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.addItem(product, 2);
      repository.addItem(product, 3);

      expect(repository.items.length, equals(1));
      expect(repository.items.first.quantity, equals(5));
    });

    test('addItem respects max stock limit', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 5,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      when(() => mockProductRepository.findById(1)).thenReturn(product);

      repository.addItem(product, 10);

      expect(repository.items.first.quantity, equals(5));
    });

    test('updateQuantity updates item quantity', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.addItem(product, 2);
      repository.updateQuantity(1, 5);

      expect(repository.items.first.quantity, equals(5));
      expect(repository.totalItems, equals(5));
      expect(repository.totalPrice, equals(50.0));
    });

    test('updateQuantity removes item when quantity <= 0', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.addItem(product, 2);
      repository.updateQuantity(1, 0);

      expect(repository.items, isEmpty);
    });

    test('updateQuantity respects max stock limit', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 3,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      when(() => mockProductRepository.findById(1)).thenReturn(product);

      repository.addItem(product, 2);
      repository.updateQuantity(1, 10);

      expect(repository.items.first.quantity, equals(3));
    });

    test('removeItem removes specific item', () async {
      await repository.loadCart();

      const product1 = StockItem(
        id: 1,
        name: 'Product 1',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );
      const product2 = StockItem(
        id: 2,
        name: 'Product 2',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 20,
      );

      repository.addItem(product1, 2);
      repository.addItem(product2, 3);
      repository.removeItem(1);

      expect(repository.items.length, equals(1));
      expect(repository.items.first.product.id, equals(2));
    });

    test('clear removes all items', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.addItem(product, 2);
      repository.clear();

      expect(repository.items, isEmpty);
      expect(repository.totalItems, equals(0));
      expect(repository.totalPrice, equals(0.0));
    });

    test('isEmpty returns true when cart is empty', () async {
      await repository.loadCart();

      expect(repository.isEmpty, isTrue);
    });

    test('isEmpty returns false when cart has items', () async {
      await repository.loadCart();

      const product = StockItem(
        id: 1,
        name: 'Test Product',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );

      repository.addItem(product, 1);

      expect(repository.isEmpty, isFalse);
    });

    test('totalItems returns sum of all quantities', () async {
      await repository.loadCart();

      const product1 = StockItem(
        id: 1,
        name: 'Product 1',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );
      const product2 = StockItem(
        id: 2,
        name: 'Product 2',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 20,
      );

      repository.addItem(product1, 3);
      repository.addItem(product2, 2);

      expect(repository.totalItems, equals(5));
    });

    test('totalPrice returns sum of price * quantity', () async {
      await repository.loadCart();

      const product1 = StockItem(
        id: 1,
        name: 'Product 1',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 10,
      );
      const product2 = StockItem(
        id: 2,
        name: 'Product 2',
        quantity: 100,
        image: 'https://example.com/image.png',
        status: StockStatus.normal,
        price: 20,
      );

      repository.addItem(product1, 3);
      repository.addItem(product2, 2);

      expect(repository.totalPrice, equals(70.0));
    });
  });
}
