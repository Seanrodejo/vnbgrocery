import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:http/http.dart' as http; 
import '../models/product.dart';
import '../models/order.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- TELEGRAM CONFIG ---
  final String _botToken = '8595213600:AAG77yfNy6K3gSvo_MesE_efMxudgiM41Qw'; 
  final String _chatId = '-5261049054'; 

  CollectionReference get _products => _firestore.collection('products');
  CollectionReference get _orders => _firestore.collection('orders');

  // Submit order with Telegram Alert
  Future<String> submitOrder(Order order) async {
    // 1. Save to Firestore
    final docRef = await _orders.add(order.toMap());
    
    // 2. Trigger Telegram Alert
    await _sendTelegramNotification(order);
    
    return docRef.id;
  }

  // PRIVATE FUNCTION: The Telegram "Brain"
  Future<void> _sendTelegramNotification(Order order) async {
    try {
      final String itemSummary = order.items
          .map((item) => "• ${item.productName} (${item.priceType}) x${item.quantity}")
          .join('\n');

      final String message = "🔔 *NEW ORDER RECEIVED!*\n\n"
          "🆔 *Ref:* `${order.referenceId}`\n"
          "👤 *Customer:* ${order.customerName}\n"
          "📞 *Phone:* ${order.customerPhone}\n"
          "📍 *Address:* ${order.customerAddress}\n\n"
          "🛒 *Items:*\n$itemSummary\n\n"
          "💰 *Total:* ₱${order.total.toStringAsFixed(2)}\n"
          "----------------------------\n"
          "Check Admin Dashboard for details.";

      final url = Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage');
      
      final response = await http.post(url, body: {
        'chat_id': _chatId,
        'text': message,
        'parse_mode': 'Markdown', 
      });

      if (response.statusCode != 200) {
        print("Telegram Failed: ${response.body}");
      }
    } catch (e) {
      print("Telegram Notification Error: $e");
    }
  }

  // --- STANDARD FUNCTIONS ---

  Future<List<Product>> getProducts({
    String sortBy = 'name',
    bool ascending = true,
  }) async {
    Query query = _products;
    if (sortBy == 'name') {
      query = query.orderBy('name', descending: !ascending);
    } else if (sortBy == 'price') {
      query = query.orderBy('vnbPrice', descending: !ascending);
    }
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await _orders.doc(orderId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<List<Order>> getOrders() async {
    final snapshot = await _orders.orderBy('createdAt', descending: true).get();
    return snapshot.docs
        .map((doc) => Order.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<Product?> getProduct(String id) async {
    final doc = await _products.doc(id).get();
    if (doc.exists) {
      return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<String> addProduct(Product product) async {
    final docRef = await _products.add(product.toMap());
    return docRef.id;
  }

  Future<void> updateProduct(Product product) async {
    await _products.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String id) async {
    await _products.doc(id).delete();
  }

  Future<void> deleteOrder(String id) async {
    await _orders.doc(id).delete();
  }

  Stream<List<Product>> getProductsStream() {
    return _products.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }
}