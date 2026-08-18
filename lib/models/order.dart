import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double price;
  final String priceType;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.price,
    required this.priceType,
  });

  // --- 🌟 NEW ENHANCEMENTS: Premium Model Getters ---
  // Easily get the total cost of this specific item line
  double get subtotal => price * quantity;

  // --- 🌟 NEW ENHANCEMENTS: copyWith Method ---
  // Standard in enterprise apps to update specific fields easily
  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? price,
    String? priceType,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      priceType: priceType ?? this.priceType,
    );
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0.0).toDouble(),
      priceType: map['priceType'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'price': price,
      'priceType': priceType,
    };
  }
}

class Order {
  final String id;
  final String referenceId;
  final List<OrderItem> items;
  final double total;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String status; // pending, confirmed, shipped, delivered, cancelled
  final DateTime createdAt;
  final DateTime? updatedAt;
  
  // --- NEW: LINK TO USER ACCOUNT ---
  final String userId; // "guest" or the actual User ID

  Order({
    required this.id,
    required this.referenceId,
    required this.items,
    required this.total,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.status,
    required this.createdAt,
    this.updatedAt,
    required this.userId, 
  });

  // --- 🌟 NEW ENHANCEMENTS: Premium Data Getters ---
  // Get the total number of physical items in the order
  int get totalItemCount => items.fold(0, (sum, item) => sum + item.quantity);
  
  // Get a perfectly formatted string for the total price
  String get formattedTotal => '₱${total.toStringAsFixed(2)}';

  // --- 🌟 NEW ENHANCEMENTS: copyWith Method ---
  Order copyWith({
    String? id,
    String? referenceId,
    List<OrderItem>? items,
    double? total,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Order(
      id: id ?? this.id,
      referenceId: referenceId ?? this.referenceId,
      items: items ?? this.items,
      total: total ?? this.total,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      referenceId: map['referenceId'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((item) => OrderItem.fromMap(item))
              .toList() ?? [],
      total: (map['total'] ?? 0.0).toDouble(),
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      customerAddress: map['customerAddress'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      // Load User ID (Default to 'guest' if missing)
      userId: map['userId'] ?? 'guest',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'referenceId': referenceId,
      'items': items.map((item) => item.toMap()).toList(),
      'total': total,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'userId': userId,
    };
  }
}