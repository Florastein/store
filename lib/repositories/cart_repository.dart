import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:store/models/products_model.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});
  
  final StockItem product;
  int quantity;
  
  Map<String, dynamic> toJson() {
    return {
      'product': product.toJson(),
      'quantity': quantity,
    };
  }
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: StockItem.fromJson(json['product']),
      quantity: json['quantity'] as int,
    );
  }
}

class CartRepository extends ChangeNotifier {
  CartRepository._();
  
  static final CartRepository instance = CartRepository._();
  
  static const String _storageKey = 'cart';
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;
  
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get isEmpty => _items.isEmpty;
  
  int get totalItems => _items.fold(0, (sum, item) => sum + item.quantity);
  
  double get totalPrice => _items.fold(
        0.0,
        (sum, item) => sum + (item.product.price ?? 0.0) * item.quantity,
      );
  
  Future<void> loadCart() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();
      
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);
      
      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _items = jsonList.map((json) => CartItem.fromJson(json)).toList();
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load cart: $e';
      _items = [];
      notifyListeners();
    }
  }
  
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_items.map((item) => item.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }
  
  void addItem(StockItem product, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    _saveCart();
    notifyListeners();
  }
  
  void updateQuantity(int productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }
    final index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].quantity = quantity;
      _saveCart();
      notifyListeners();
    }
  }
  
  void removeItem(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }
  
  void clear() {
    _items = [];
    _saveCart();
    notifyListeners();
  }
}