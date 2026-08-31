import '../../models/products_model.dart';

class CartItem {
  CartItem({required this.product, required this.quantity});

  final StockItem product;
  int quantity;

  Map<String, dynamic> toJson() => {
    'product': product.toJson(),
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    product: StockItem.fromJson(json['product']),
    quantity: json['quantity'] as int,
  );
}

abstract class CartRepository {
  List<CartItem> get items;
  bool get isLoading;
  String? get error;
  bool get isEmpty;
  int get totalItems;
  double get totalPrice;

  Future<void> loadCart();

  void addItem(StockItem product, int quantity);
  void updateQuantity(int productId, int quantity);
  void removeItem(int productId);
  void clear();
}
