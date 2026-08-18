import 'package:flutter/foundation.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  int quantity;
  final String priceType; // 'retail' or 'wholesale'

  CartItem({
    required this.product,
    this.quantity = 1,
    this.priceType = 'wholesale',
  });

  double get price =>
      priceType == 'retail' ? product.retailPrice : product.wholesalePrice;

  double get total => price * quantity;
}

class CartProvider with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => _items;

  int get itemCount => _items.length;

  // Calculates total number of items for the red badge
  int get totalQuantity =>
      _items.values.fold(0, (sum, item) => sum + item.quantity);

  // Calculates total price
  double get totalAmount =>
      _items.values.fold(0.0, (sum, item) => sum + item.total);

  // Add item (Handles composite key: ID + PriceType)
  void addItem(Product product, String priceType) {
    final key = '${product.id}_$priceType';
    if (_items.containsKey(key)) {
      _items[key]!.quantity++;
    } else {
      _items[key] = CartItem(product: product, priceType: priceType);
    }
    notifyListeners();
  }

  // Remove single quantity (or delete if 0)
  void removeItem(String productId, String priceType) {
    final key = '${productId}_$priceType';
    if (_items.containsKey(key)) {
      if (_items[key]!.quantity > 1) {
        _items[key]!.quantity--;
      } else {
        _items.remove(key);
      }
      notifyListeners();
    }
  }

  // FIXED: Completely remove a specific row (e.g., remove Coke Retail but keep Coke Wholesale)
  void removeEntireProduct(String productId, String priceType) {
    final key = '${productId}_$priceType';
    _items.remove(key);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // Helper to check if specific variant is in cart
  bool isInCart(String productId, String priceType) {
    return _items.containsKey('${productId}_$priceType');
  }
}