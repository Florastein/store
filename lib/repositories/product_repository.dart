import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/products_model.dart';
import 'interfaces/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({CacheManager? cacheManager})
    : _cacheManager = cacheManager ?? DefaultCacheManager();

  final CacheManager _cacheManager;

  static const String _storageKey = 'products';
  List<StockItem> _products = [];
  bool _isLoading = false;
  String? _error;
  final List<VoidCallback> _listeners = [];

  @override
  List<StockItem> get products => _products;

  @override
  bool get isLoading => _isLoading;

  @override
  String? get error => _error;

  @override
  int get nextId => _products.isEmpty
      ? 1
      : _products.map((p) => p.id).reduce((a, b) => a > b ? a : b) + 1;

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
  Uint8List? imageBytesFor(int productId, String imageUrl) => null;

  @override
  void loadProductImages() {
    _precacheImages();
  }

  @override
  Future<void> loadProducts() async {
    try {
      _isLoading = true;
      _error = null;
      _notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_storageKey);

      if (jsonString != null) {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        final storedProducts = jsonList
            .map((json) => StockItem.fromJson(json))
            .toList();
        _products = storedProducts.map(_migrateImageUrl).toList();
        if (!_sameImageUrls(storedProducts, _products)) {
          await _saveProducts();
        }
      } else {
        _products = _getDefaultProducts();
        await _saveProducts();
      }

      _isLoading = false;
      _notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to load products: $e';
      _products = _getDefaultProducts();
      _notifyListeners();
    }
    _precacheImages();
  }

  Future<void> _precacheImages() async {
    for (final product in _products) {
      try {
        await _cacheManager.getSingleFile(product.image);
      } catch (e) {
        debugPrint('Failed to precache image for product ${product.id}: $e');
      }
    }
  }

  Future<void> _saveProducts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = jsonEncode(_products.map((p) => p.toJson()).toList());
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Failed to save products: $e');
    }
  }

  @override
  void add(StockItem item) {
    _products = [..._products, item];
    _saveProducts();
    _notifyListeners();
    _precacheSingleImage(item.image);
  }

  @override
  void updateQuantity(int id, int newQuantity) {
    final index = _products.indexWhere((p) => p.id == id);
    if (index < 0) {
      return;
    }

    final updated = _products[index].copyWith(
      quantity: newQuantity,
      status: _deriveStatus(newQuantity),
    );
    _products = List<StockItem>.from(_products)..[index] = updated;
    _saveProducts();
    _notifyListeners();
  }

  @override
  void remove(int id) {
    _products = _products.where((p) => p.id != id).toList();
    _saveProducts();
    _notifyListeners();
  }

  @override
  void replace(StockItem updated) {
    final index = _products.indexWhere((p) => p.id == updated.id);
    if (index < 0) {
      return;
    }
    final previous = _products[index];
    _products = List<StockItem>.from(_products)..[index] = updated;
    _saveProducts();
    _notifyListeners();
    if (previous.image != updated.image) {
      _precacheSingleImage(updated.image);
    }
  }

  Future<void> _precacheSingleImage(String url) async {
    try {
      await _cacheManager.getSingleFile(url);
    } catch (e) {
      debugPrint('Failed to precache image: $e');
    }
  }

  @override
  StockItem? findByBarcode(String barcode) {
    try {
      return _products.firstWhere((p) => p.barcode == barcode);
    } catch (_) {
      return null;
    }
  }

  @override
  StockItem? findById(int id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  static StockStatus _deriveStatus(int quantity) {
    if (quantity == 0) {
      return StockStatus.outOfStock;
    }
    if (quantity <= 10) {
      return StockStatus.lowStock;
    }
    return StockStatus.normal;
  }

  static StockItem _migrateImageUrl(StockItem product) {
    const legacyPlaceholder = 'https://via.placeholder.com/120?text=';
    if (!product.image.startsWith(legacyPlaceholder)) {
      return product;
    }

    return product.copyWith(
      image: product.image.replaceFirst(
        legacyPlaceholder,
        'https://placehold.co/120x120?text=',
      ),
    );
  }

  static bool _sameImageUrls(List<StockItem> first, List<StockItem> second) =>
      first.length == second.length &&
      Iterable<int>.generate(
        first.length,
      ).every((index) => first[index].image == second[index].image);

  List<StockItem> _getDefaultProducts() => [
    StockItem(
      id: 1,
      name: 'KitKat',
      quantity: 80,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT_6Ib8mvzzQphNv38JzfJJNmY_ODGdzOBgHDG45N5R4Q&s=10',
      status: StockStatus.normal,
      barcode: '5000159402974',
      price: 2.50,
      expiryDate: DateTime(2025, 12, 31),
      description:
          'Crispy wafer bar with chocolate coating. Perfect for a quick snack.',
    ),
    StockItem(
      id: 2,
      name: "Lay's",
      quantity: 200,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSgczredDV4jryfxPc6oxJo5FOcdkPHrlANXXYUdALByg&s=10',
      status: StockStatus.normal,
      barcode: '8901072100983',
      price: 1.50,
      expiryDate: DateTime(2025, 11, 15),
      description: 'Crispy potato chips with a light and savory flavor.',
    ),
    StockItem(
      id: 3,
      name: 'Pepsi',
      quantity: 6,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcT6XyvVwdEGewdBvALs-JzE--U0oSTFRQBlHqWHunoA7w&s=10',
      status: StockStatus.lowStock,
      barcode: '5449000131805',
      price: 1.20,
      expiryDate: DateTime(2025, 10, 20),
      description: 'Refreshing cola drink. Serve ice cold for best taste.',
    ),
    StockItem(
      id: 4,
      name: 'Nutella',
      quantity: 0,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTqC-zPfrAFc-XXhHqoMSKDYgqwnNtJXUdcT0so6Ki-OQ&s=10',
      status: StockStatus.outOfStock,
      barcode: '8000500010620',
      price: 8.99,
      expiryDate: DateTime(2025, 9, 10),
      description: 'Delicious hazelnut chocolate spread. Great for breakfast.',
    ),
    StockItem(
      id: 5,
      name: 'Cheetos',
      quantity: 80,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTJhiQHg0RE2gDOFkCKcZnMs5UCMxd7vxHKwYYNN18Izg&s=10',
      status: StockStatus.normal,
      barcode: '8901063032033',
      price: 1.75,
      expiryDate: DateTime(2025, 12, 25),
      description: 'Cheesy puffed corn snack. Irresistibly crunchy!',
    ),
    StockItem(
      id: 6,
      name: 'Oreo',
      quantity: 50,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRbDV2Lw-1P5ahsSpaKnCaVC0N4CfHiPUIsGtTikiZC4w&s=10',
      status: StockStatus.normal,
      barcode: '7622210449283',
      price: 3.50,
      expiryDate: DateTime(2026, 1, 15),
      description: 'Classic chocolate sandwich cookies with cream filling.',
    ),
    StockItem(
      id: 7,
      name: 'Bottle Water',
      quantity: 100,
      image:
          'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcR64rFsx3G2W6TMgwVU4ilQu8Qa_6HOdnVvVVpr66a3Fg&s=10',
      status: StockStatus.normal,
      barcode: '5449000018246',
      price: 0.50,
      expiryDate: DateTime(2025, 6, 30),
      description: 'Pure drinking water. 500ml bottle. Stay hydrated!',
    ),
    StockItem(
      id: 8,
      name: 'Tide plus',
      quantity: 30,
      image: 'https://placehold.co/120x120?text=Tide',
      status: StockStatus.normal,
      barcode: '4902430401539',
      price: 5.99,
      expiryDate: DateTime(2026, 3, 20),
      description:
          'Advanced laundry detergent. Removes tough stains effectively.',
    ),
    StockItem(
      id: 9,
      name: 'Vanish gold',
      quantity: 19,
      image: 'https://placehold.co/120x120?text=Vanish',
      status: StockStatus.normal,
      barcode: '8717644489318',
      price: 3.99,
      expiryDate: DateTime(2026, 2, 10),
      description: 'Powerful stain remover for white clothes.',
    ),
    StockItem(
      id: 10,
      name: 'Colgate',
      quantity: 0,
      image: 'https://placehold.co/120x120?text=Colgate',
      status: StockStatus.outOfStock,
      barcode: '8901072100099',
      price: 1.99,
      expiryDate: DateTime(2025, 8, 15),
      description: 'Fresh mint toothpaste for healthy teeth.',
    ),
    StockItem(
      id: 11,
      name: 'Dove',
      quantity: 5,
      image: 'https://placehold.co/120x120?text=Dove',
      status: StockStatus.lowStock,
      barcode: '8717644481152',
      price: 2.50,
      expiryDate: DateTime(2026, 1, 20),
      description: 'Gentle beauty bar for sensitive skin.',
    ),
    StockItem(
      id: 12,
      name: 'Lifebuoy',
      quantity: 0,
      image: 'https://placehold.co/120x120?text=Lifebuoy',
      status: StockStatus.outOfStock,
      barcode: '8901072100181',
      price: 1.50,
      expiryDate: DateTime(2025, 9, 5),
      description: 'Antibacterial soap bar. Kills 99.9% germs.',
    ),
    StockItem(
      id: 13,
      name: 'Sunsilk',
      quantity: 25,
      image: 'https://placehold.co/120x120?text=Sunsilk',
      status: StockStatus.normal,
      barcode: '8901072100044',
      price: 3.75,
      expiryDate: DateTime(2026, 4, 30),
      description: 'Sunscreen hair care shampoo. Protects against UV damage.',
    ),
    StockItem(
      id: 14,
      name: 'Head & Shoulders',
      quantity: 0,
      image: 'https://placehold.co/120x120?text=H%26S',
      status: StockStatus.outOfStock,
      barcode: '4902430201092',
      price: 4.99,
      expiryDate: DateTime(2025, 10, 10),
      description: 'Anti-dandruff shampoo. Effective scalp care.',
    ),
    StockItem(
      id: 15,
      name: 'Pantene',
      quantity: 10,
      image: 'https://placehold.co/120x120?text=Pantene',
      status: StockStatus.lowStock,
      barcode: '4902430201085',
      price: 4.50,
      expiryDate: DateTime(2025, 12, 5),
      description: 'Premium care shampoo for smooth and shiny hair.',
    ),
    StockItem(
      id: 16,
      name: 'Fair & Lovely',
      quantity: 0,
      image: 'https://placehold.co/120x120?text=F%26L',
      status: StockStatus.outOfStock,
      barcode: '8901072100105',
      price: 6.99,
      expiryDate: DateTime(2025, 11, 15),
      description: 'Fairness cream with SPF 30. Complete skin brightening.',
    ),
  ];
}
