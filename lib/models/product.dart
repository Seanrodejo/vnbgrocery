class Product {
  final String id;
  final String name;
  final double retailPrice;
  final double wholesalePrice;
  final String description;
  final String imageUrl;
  final String category;
  
  // --- NEW FIELDS FOR PROMO CODES ---
  final String couponCode;      // e.g., "SAVE20"
  final double discountAmount;  // e.g., 20.0

  Product({
    required this.id,
    required this.name,
    required this.retailPrice,
    required this.wholesalePrice,
    required this.description,
    required this.imageUrl,
    required this.category,
    this.couponCode = '',      // Default to empty (no coupon)
    this.discountAmount = 0.0, // Default to 0 discount
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      name: map['name'] ?? '',
      retailPrice: (map['marketPrice'] ?? 0.0).toDouble(),
      wholesalePrice: (map['vnbPrice'] ?? 0.0).toDouble(),
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      category: (map['category'] ?? '').isEmpty ? 'Others' : map['category'],
      // Load Coupon Data
      couponCode: map['couponCode'] ?? '',
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'marketPrice': retailPrice,
      'vnbPrice': wholesalePrice,
      'description': description,
      'imageUrl': imageUrl,
      'category': category,
      // Save Coupon Data
      'couponCode': couponCode,
      'discountAmount': discountAmount,
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? retailPrice,
    double? wholesalePrice,
    String? description,
    String? imageUrl,
    String? category,
    String? couponCode,
    double? discountAmount,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      retailPrice: retailPrice ?? this.retailPrice,
      wholesalePrice: wholesalePrice ?? this.wholesalePrice,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      couponCode: couponCode ?? this.couponCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }

  double get savings => retailPrice - wholesalePrice;
}