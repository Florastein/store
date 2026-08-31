import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/products_model.dart';
import 'interfaces/cart_repository.dart';
import 'interfaces/product_repository.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl({required ProductRepository productRepository})
    : _productRepository = productRepository;

  final ProductRepository _productRepository;

  static const String _storageKey = 'cart';
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  final List<VoidCallback> _listeners = [];

  @override
  List<CartItem> get items => _items;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  bool get isEmpty => _items.isEmpty;

  @override
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);

  @override
  double get totalPrice => _items.fold(
    0,
    (sum, item) => sum + (item.product.price ?? 0.0) * item.quantity,
  );

  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener();
    }
  }

  @override
  Future<void> loadCart() async {
    try {
      _isLoading = true;
      _error = null;
      _notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _items = jsonList.map((json) => CartItem.fromJson(json)).toList();
      }

      _isLoading = false;
      _notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load cart: $e';
      _items = [];
      _notifyListeners();
    }
  }

  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(
        _items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }

  @override
  void addItem(StockItem product, int quantity) {
    final stock = _productRepository.findById(product.id);
    final maxStock = stock?.quantity ?? product.quantity;
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final newQty = _items[index].quantity + quantity;
      _items[index].quantity = newQty > maxStock ? maxStock : newQty;
    } else {
      _items.add(
        CartItem(
          product: product,
          quantity: quantity > maxStock ? maxStock : quantity,
        ),
      );
    }
    _saveCart();
    _notifyListeners();
  }

  @override
  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final stock = _productRepository.findById(productId);
      final maxStock = stock?.quantity ?? _items[index].product.quantity;
      _items[index].quantity = quantity > maxStock ? maxStock : quantity;
      _saveCart();
      _notifyListeners();
    }
  }

  @override
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    _notifyListeners();
  }

  @override
  void clear() {
    _items = [];
    _saveCart();
    _notifyListeners();
  }
}
