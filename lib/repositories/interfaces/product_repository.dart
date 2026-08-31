import 'dart:typed_data';

import '../../models/products_model.dart';

abstract class ProductRepository {
  List<StockItem> get products;
  bool get isLoading;
  String? get error;
  int get nextId;

  Future<void> loadProducts();
  void loadProductImages();
  Uint8List? imageBytesFor(int productId, String imageUrl);

  void add(StockItem item);
  void updateQuantity(int id, int newQuantity);
  void remove(int id);
  void replace(StockItem updated);

  StockItem? findByBarcode(String barcode);
  StockItem? findById(int id);
}
