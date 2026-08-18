import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart' as app_order;
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isSubmitting = false;
  bool _showGcashQr = false; // Toggle for QR code

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  double _calculateDeliveryFee(double total) {
    return 0; // Free delivery logic
  }

  String _generateReferenceId() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd').format(now);
    final randomId = now.millisecondsSinceEpoch.toString().substring(8);
    return 'VN-$dateStr-$randomId';
  }

  void _applyCoupon(CartProvider cart) {
    final code = _couponController.text.trim();
    if (code.isEmpty) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Coupon applied! (Discount logic pending)")),
    );
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)), // ADDED: Smoother dialog radius
        backgroundColor: Colors.white,
        elevation: 10, // ADDED: Nice shadow
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(28), // ADDED: Slightly more breathing room
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Scan to Pay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)), // ADDED: Bolder, larger title
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20), // ADDED: Ripple effect respects circle
                    child: Container( // ADDED: Soft grey background to close button
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                      child: const Icon(Icons.close, color: Colors.black54, size: 20),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20), // ADDED: Smoother image container
                  border: Border.all(color: Colors.blue.shade100, width: 3), // ADDED: GCash Blue tinted border
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2) // ADDED: Glow behind QR
                  ]
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    'assets/images/gcash_qr.jpg',
                    width: 250, height: 250, fit: BoxFit.cover,
                    errorBuilder: (c,e,s) => Container(
                      width: 250, height: 250, color: Colors.grey[50],
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, size: 50, color: Colors.grey.shade400), // ADDED: Better fallback icon
                          const SizedBox(height: 8),
                          Text("QR Code not found", style: TextStyle(color: Colors.grey.shade500)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Send screenshot of payment to:', style: TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 6),
              Container( // ADDED: Highlight box for the messenger handle
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text('Messenger: @ruviejoy.tolentino', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF6B35), fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitOrder(CartProvider cartProvider) async {
    if (!_formKey.currentState!.validate()) return;
    if (cartProvider.items.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final userId = user?.uid ?? 'guest';

      // 1. Convert Cart Items to Order Items
      final items = cartProvider.items.values.map((item) => app_order.OrderItem(
        productId: item.product.id,        // 🔥 FIXED
        productName: item.product.name,    // 🔥 FIXED
        quantity: item.quantity,
        price: item.price,
        priceType: item.priceType,
      )).toList();

      final total = cartProvider.totalAmount;
      final order = app_order.Order(
        id: '', 
        referenceId: _generateReferenceId(),
        items: items,
        total: total,
        customerName: _nameController.text,
        customerPhone: _phoneController.text,
        customerAddress: _addressController.text,
        status: 'pending',
        createdAt: DateTime.now(),
        userId: userId,
      );

      await _firebaseService.submitOrder(order);
      
      final itemSummary = items.map((i) => '${i.productName} (${i.priceType}) x${i.quantity}').join('\n');
      final message = 'New Order!\nRef: ${order.referenceId}\n\nItems:\n$itemSummary\n\nTotal: ₱${total.toStringAsFixed(2)}\n\nCustomer: ${order.customerName}\nAddress: ${order.customerAddress}';
      final messengerUrl = 'https://m.me/ruviejoy.tolentino?text=${Uri.encodeComponent(message)}';

      cartProvider.clearCart();

      if (!mounted) return;
      
      // SHOW RECEIPT DIALOG
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0, // ADDED: Remove default dialog shadow to use custom one
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32), // ADDED: Better padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16), // ADDED: More rounded receipt
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, 10)) // ADDED: Premium floating shadow
                    ],
                  ),
                  child: Column(
                    children: [
                      Container( // ADDED: Circle background for receipt icon
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                        child: Icon(Icons.check_circle, size: 48, color: Colors.green.shade600), // ADDED: Success icon instead of standard receipt
                      ),
                      const SizedBox(height: 16),
                      const Text("VNB GROCERY PH", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: 0.5, color: Colors.black87)), // ADDED: Modern font style
                      const SizedBox(height: 4),
                      const Text("OFFICIAL RECEIPT", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.5)), // ADDED: Spaced out subtitle
                      const SizedBox(height: 20),
                      
                      // ADDED: Dotted Divider simulation
                      Row(
                        children: List.generate(30, (index) => Expanded(
                          child: Container(color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade400, height: 1),
                        )),
                      ),
                      
                      const SizedBox(height: 16),
                      // Receipt Items
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6), // ADDED: Slightly more spacing between items
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${item.quantity}x", style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.black87)), // ADDED: Removed forced courier, looks cleaner
                            const SizedBox(width: 12),
                            Expanded(child: Text(item.productName, style: const TextStyle(fontSize: 13, color: Colors.black87))),
                            Text("₱${(item.price * item.quantity).toStringAsFixed(2)}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      )),
                      const SizedBox(height: 16),
                      
                      // ADDED: Dotted Divider simulation
                      Row(
                        children: List.generate(30, (index) => Expanded(
                          child: Container(color: index % 2 == 0 ? Colors.transparent : Colors.grey.shade400, height: 1),
                        )),
                      ),
                      
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("TOTAL", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.black87)), // ADDED: Modern bold
                          Text("₱${total.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Color(0xFFEE4D2D))), // ADDED: Emphasized total in brand color
                        ],
                      ),
                      const SizedBox(height: 30),
                      Container( // ADDED: Highlight box for instructions
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_outlined, size: 14, color: Colors.grey.shade700),
                            const SizedBox(width: 6),
                            Text("Please screenshot this receipt", style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () { Navigator.pop(context); context.go('/'); }, 
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white, 
                          padding: const EdgeInsets.symmetric(vertical: 16), // ADDED: Taller buttons
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)) // ADDED: Rounded buttons
                        ), 
                        child: const Text('Close', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 16))
                      )
                    ), 
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async { Navigator.pop(context); context.go('/'); if (await canLaunchUrl(Uri.parse(messengerUrl))) await launchUrl(Uri.parse(messengerUrl)); }, 
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0084FF), // ADDED: Official Messenger Blue
                          elevation: 5, // ADDED: Shadow to pop
                          shadowColor: const Color(0xFF0084FF).withOpacity(0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ), 
                        child: const Row( // ADDED: Icon to button
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 18, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Messenger', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ],
                        )
                      )
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // 🔥 HELPER: Build Premium Floating Section Cards 🔥
  Widget _buildSection(String title, Widget content, {Widget? trailing}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ADDED: Side margins to detach from screen edges
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16), // ADDED: Modern rounded corners
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)) // ADDED: Soft floating shadow
        ],
        border: Border.all(color: Colors.grey.shade100, width: 1), // ADDED: Very subtle border definition
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0), // ADDED: More padding
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87, letterSpacing: 0.2)), // ADDED: Bolder title
                if (trailing != null) trailing,
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey.shade100), // ADDED: Softer divider
          Padding(
            padding: const EdgeInsets.all(16.0), // ADDED: More padding
            child: content,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final user = FirebaseAuth.instance.currentUser;
    final primaryColor = const Color(0xFFEE4D2D); // Shopee Orange

    final total = cartProvider.totalAmount;
    final dp = total * 0.20;
    final weekly = (total - dp) / 6;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // ADDED: Slightly cooler, cleaner grey background
      appBar: AppBar(
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), // ADDED: Bolder app bar text
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0, // ADDED: Flat modern app bar
        centerTitle: true, // ADDED: Centered title looks more premium
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize( // ADDED: Subtle hairline border under appbar instead of heavy shadow
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20), // ADDED: Modern iOS style back arrow
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (cartProvider.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep_rounded, color: Colors.red.shade400, size: 26), // ADDED: Softer red, better icon
              tooltip: 'Clear Cart',
              onPressed: () {
                cartProvider.clearCart();
              },
            )
        ],
      ),
      body: cartProvider.items.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container( // ADDED: Soft circle behind the empty cart icon
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)]),
                    child: Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300), // ADDED: Changed to shopping bag
                  ),
                  const SizedBox(height: 24),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)), // ADDED: Bolder text
                  const SizedBox(height: 8),
                  Text('Looks like you haven\'t added\nanything yet.', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey.shade500, height: 1.4)), // ADDED: Subtitle text
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () => context.go('/'), 
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor, 
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16), // ADDED: Larger empty cart button
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), // ADDED: Pill shaped button
                      elevation: 4,
                      shadowColor: primaryColor.withOpacity(0.4)
                    ),
                    child: const Text('Start Shopping', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 8), // ADDED: Top spacing
                        // 🔥 1. ADDRESS SECTION 🔥
                        _buildSection(
                          'Delivery Address',
                          Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration( // ADDED: Upgraded Input Decoration (Filled)
                                    labelText: 'Full Name', 
                                    prefixIcon: const Icon(Icons.person_outline), 
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                                  ),
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _phoneController,
                                  decoration: InputDecoration(
                                    labelText: 'Phone Number', 
                                    prefixIcon: const Icon(Icons.phone_outlined), 
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                                  ),
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Complete Address (House/Block/Lot/Street)', 
                                    alignLabelWithHint: true, // ADDED: Aligns label to top for multiline
                                    prefixIcon: const Padding(padding: EdgeInsets.only(bottom: 24), child: Icon(Icons.location_on_outlined)), // ADDED: Pushes icon up
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16)
                                  ),
                                  maxLines: 2,
                                  validator: (v) => v!.isEmpty ? 'Required' : null,
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 🔥 2. ORDER SUMMARY SECTION 🔥
                        _buildSection(
                          'Order Summary',
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: cartProvider.items.length,
                            separatorBuilder: (_, __) => Padding( // ADDED: Softer, inset divider between items
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: Colors.grey.shade100, height: 1),
                            ),
                            itemBuilder: (ctx, i) {
                              final item = cartProvider.items.values.toList()[i];
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4.0), // ADDED: Tighter vertical padding
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 85, height: 85, // ADDED: Slightly larger image
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50, // ADDED: Background for images with transparency
                                        borderRadius: BorderRadius.circular(12), // ADDED: Rounded product image
                                        border: Border.all(color: Colors.grey.shade200),
                                        image: item.product.imageUrl.isNotEmpty 
                                            ? DecorationImage(image: NetworkImage(item.product.imageUrl), fit: BoxFit.cover)
                                            : null,
                                      ),
                                      child: item.product.imageUrl.isEmpty ? const Icon(Icons.image, color: Colors.grey) : null,
                                    ),
                                    const SizedBox(width: 16), // ADDED: More spacing
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.product.name, 
                                              maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)), // ADDED: Bolder item name
                                          const SizedBox(height: 6),
                                          Container( // ADDED: Highlight pill for variation type
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
                                            child: Text(item.priceType.toUpperCase(), style: TextStyle(fontSize: 10, color: Colors.grey.shade700, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('₱${item.price.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryColor)), // ADDED: Emphasized price
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.shade50, // ADDED: Filled background for quantity controller
                                                  border: Border.all(color: Colors.grey.shade200), 
                                                  borderRadius: BorderRadius.circular(8) // ADDED: Rounded pill shape
                                                ),
                                                child: Row(
                                                  children: [
                                                    InkWell( // ADDED: Replaced IconButton with InkWell for tighter custom sizing
                                                      onTap: () => cartProvider.removeItem(item.product.id, item.priceType),
                                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                                      child: const Padding(padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.remove, size: 16, color: Colors.black54)),
                                                    ),
                                                    Container( // ADDED: Dividers inside the quantity selector
                                                      width: 1, height: 16, color: Colors.grey.shade300,
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 14),
                                                      child: Text('${item.quantity}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)), // ADDED: Bolder quantity number
                                                    ),
                                                    Container(
                                                      width: 1, height: 16, color: Colors.grey.shade300,
                                                    ),
                                                    InkWell(
                                                      onTap: () => cartProvider.addItem(item.product, item.priceType),
                                                      borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                                      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Icon(Icons.add, size: 16, color: primaryColor)),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),

                        // 🔥 3. VOUCHER SECTION 🔥
                        if (user != null)
                          _buildSection(
                            'Platform Voucher',
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _couponController,
                                    decoration: InputDecoration(
                                      hintText: "Enter Discount Code", 
                                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                                      prefixIcon: Icon(Icons.local_activity_outlined, color: primaryColor, size: 20), // ADDED: Icon
                                      filled: true,
                                      fillColor: Colors.grey.shade50,
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade200)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: primaryColor)),
                                      isDense: true, 
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12) // ADDED: Better padding
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton(
                                  onPressed: () => _applyCoupon(cartProvider),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.black87, // ADDED: Changed to black for contrast against the orange theme
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20)
                                  ),
                                  child: const Text("Apply", style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ),

                        // 🔥 4. PAYMENT OPTION SECTION 🔥
                        _buildSection(
                          'Payment Details',
                          Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20), // ADDED: More padding
                                decoration: BoxDecoration(
                                  gradient: LinearGradient( // ADDED: Premium gradient background
                                    colors: [Colors.orange.shade50, const Color(0xFFFFF0EC)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ), 
                                  borderRadius: BorderRadius.circular(12), // ADDED: Rounded corners
                                  border: Border.all(color: Colors.orange.shade200, width: 1),
                                  boxShadow: [BoxShadow(color: Colors.orange.withOpacity(0.05), blurRadius: 10)] // ADDED: Inner glow
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_month, size: 18, color: Colors.orange.shade900), // ADDED: Icon to title
                                        const SizedBox(width: 8),
                                        Text("Installment Plan Available", style: TextStyle(fontWeight: FontWeight.w900, color: Colors.orange.shade900, fontSize: 15)), // ADDED: Bolder title
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("Downpayment (20%)", style: TextStyle(color: Colors.orange.shade900, fontSize: 13)), Text("₱${dp.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 15))]),
                                    const SizedBox(height: 6), // ADDED: Spacing between lines
                                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text("6 Weekly Payments", style: TextStyle(color: Colors.orange.shade900, fontSize: 13)), Text("₱${weekly.toStringAsFixed(2)}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange.shade900, fontSize: 15))]),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container( // ADDED: Wrapped ListTile in a bordered container
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade200),
                                  borderRadius: BorderRadius.circular(12)
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  leading: Container( // ADDED: Blue tint behind QR icon
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Icon(Icons.qr_code_scanner, color: Colors.blue.shade700)
                                  ),
                                  title: const Text('Show GCash QR Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                                  onTap: _showQRDialog,
                                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // ADDED: Ripple effect respects borders
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40), // ADDED: More bottom breathing room
                      ],
                    ),
                  ),
                ),

                // 🔥 SHOPEE-STYLE BOTTOM BAR 🔥
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ADDED: Better side padding
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -5))] // ADDED: Softer, wider floating shadow
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('Total Payment', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              Text('₱${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: primaryColor, letterSpacing: -0.5)), // ADDED: Tighter, larger price
                            ],
                          ),
                        ),
                        const SizedBox(width: 16), // ADDED: More spacing before button
                        Expanded(
                          flex: 2, // ADDED: Made button slightly wider
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : () => _submitOrder(cartProvider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor, 
                              padding: const EdgeInsets.symmetric(vertical: 16), // ADDED: Taller button
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // ADDED: Rounded edges
                              elevation: 4, // ADDED: Button shadow
                              shadowColor: primaryColor.withOpacity(0.5)
                            ),
                            child: _isSubmitting
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : const Text('Place Order', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}