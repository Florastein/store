enum StockStatus { normal, lowStock, outOfStock }

class StockItem {
  const StockItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.image,
    required this.status,
    this.barcode,
    this.price,
    this.expiryDate,
    this.description,
  });

  final int id;
  final String name;
  final int quantity;
  final String image;
  final StockStatus status;
  final String? barcode;
  final double? price;
  final DateTime? expiryDate;
  final String? description;

  StockItem copyWith({
    int? id,
    String? name,
    int? quantity,
    String? image,
    StockStatus? status,
    String? barcode,
    double? price,
    DateTime? expiryDate,
    String? description,
  }) {
    return StockItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      image: image ?? this.image,
      status: status ?? this.status,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      expiryDate: expiryDate ?? this.expiryDate,
      description: description ?? this.description,
    );
  }

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as int,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      image: json['image'] as String,
      status: StockStatus.values.byName(json['status'] as String),
      barcode: json['barcode'] as String?,
      price: json['price'] as double?,
      expiryDate:
          json['expiryDate'] != null ? DateTime.parse(json['expiryDate']) : null,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'image': image,
      'status': status.name,
      'barcode': barcode,
      'price': price,
      'expiryDate': expiryDate?.toIso8601String(),
      'description': description,
    };
  }
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
    this.createdAt,
  });

  final int id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? avatarUrl;
  final DateTime? createdAt;

  UserAccount copyWith({
    int? id,
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
    String? avatarUrl,
    DateTime? createdAt,
  }) {
    return UserAccount(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      role: UserRole.values.byName(json['role'] as String),
      phoneNumber: json['phoneNumber'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.name,
      'phoneNumber': phoneNumber,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}

enum UserRole { customer, cashier, admin }
