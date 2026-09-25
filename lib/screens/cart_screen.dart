import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
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

  // CLAYMORPHISM COLORS (Candy Palette)
  final Color _canvas = const Color(0xFFF4F1FA);
  final Color _primaryViolet = const Color(0xFF7C3AED);
  final Color _primaryVioletLight = const Color(0xFFA78BFA);
  final Color _hotPink = const Color(0xFFDB2777);
  final Color _secondaryOrange = const Color(0xFFFF9D42);
  final Color _darkText = const Color(0xFF332F3A);
  final Color _mutedText = const Color(0xFF635F69);

  // CLAYMORPHISM SHADOWS
  List<BoxShadow> get _clayCardShadow => [
    BoxShadow(
      color: const Color(0xFFA096B4).withOpacity(0.2),
      blurRadius: 32,
      offset: const Offset(16, 16),
    ),
    const BoxShadow(
      color: Colors.white,
      blurRadius: 24,
      offset: Offset(-10, -10),
    ),
  ];

  List<BoxShadow> get _clayHoverShadow => [
    BoxShadow(
      color: const Color(0xFFA096B4).withOpacity(0.3),
      blurRadius: 40,
      offset: const Offset(20, 20),
    ),
    const BoxShadow(
      color: Colors.white,
      blurRadius: 30,
      offset: Offset(-12, -12),
    ),
  ];

  List<BoxShadow> get _clayButtonShadow => [
    BoxShadow(
      color: _primaryViolet.withOpacity(0.4),
      blurRadius: 24,
      offset: const Offset(12, 12),
    ),
    BoxShadow(
      color: Colors.white.withOpacity(0.5),
      blurRadius: 16,
      offset: const Offset(-8, -8),
    ),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
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
      SnackBar(
        content: Text(
          "Coupon applied! (Discount logic pending)",
          style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 420,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(40),
              boxShadow: _clayCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Scan to Pay',
                      style: GoogleFonts.nunito(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: _darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAE5F0),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.03),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/gcash_qr.jpg',
                      width: 250,
                      height: 250,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 250,
                        height: 250,
                        color: Colors.white,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "QR Code missing",
                              style: GoogleFonts.dmSans(
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  'Send screenshot of payment to:',
                  style: GoogleFonts.dmSans(fontSize: 15, color: _mutedText),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.facebook,
                        color: Color(0xFF0084FF),
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Messenger: @ruviejoy.tolentino',
                        style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0084FF),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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

      final items = cartProvider.items.values
          .map(
            (item) => app_order.OrderItem(
              productId: item.product.id,
              productName: item.product.name,
              quantity: item.quantity,
              price: item.price,
              priceType: item.priceType,
            ),
          )
          .toList();

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

      final itemSummary = items
          .map((i) => '${i.productName} (${i.priceType}) x${i.quantity}')
          .join('\n');

      final message =
          'New Order!\nRef: ${order.referenceId}\n\nItems:\n$itemSummary\n\nTotal: ₱${total.toStringAsFixed(2)}\n\nCustomer: ${order.customerName}\nAddress: ${order.customerAddress}';
      final messengerUrl =
          'https://m.me/ruviejoy.tolentino?text=${Uri.encodeComponent(message)}';

      cartProvider.clearCart();

      if (!mounted) return;

      // SHOW SUCCESS RECEIPT DIALOG (Claymorphism style)
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.4),
        builder: (context) => BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 480),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 56,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(48),
                      boxShadow: _clayCardShadow,
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_circle_rounded,
                            size: 64,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          "ORDER CONFIRMED",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 28,
                            color: _darkText,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Reference: ${order.referenceId.split('-').last}",
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            color: _mutedText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                color: index % 2 == 0
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                height: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...items.map(
                          (item) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAE5F0),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    "${item.quantity}x",
                                    style: GoogleFonts.nunito(
                                      fontWeight: FontWeight.w900,
                                      color: _primaryViolet,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.productName,
                                    style: GoogleFonts.dmSans(
                                      fontSize: 15,
                                      color: _darkText,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  "₱${(item.price * item.quantity).toStringAsFixed(2)}",
                                  style: GoogleFonts.nunito(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: _darkText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: List.generate(
                            30,
                            (index) => Expanded(
                              child: Container(
                                color: index % 2 == 0
                                    ? Colors.transparent
                                    : Colors.grey.shade300,
                                height: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "TOTAL PAID",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: _mutedText,
                                letterSpacing: 1.5,
                              ),
                            ),
                            Text(
                              "₱${total.toStringAsFixed(2)}",
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 32,
                                color: _primaryViolet,
                                letterSpacing: -1,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _secondaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                size: 20,
                                color: _secondaryOrange,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                "Please take a screenshot of this receipt",
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  color: _secondaryOrange,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                context.go('/');
                              },
                              child: Container(
                                height: 64,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                ),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  boxShadow: _clayCardShadow,
                                ),
                                child: Text(
                                  'Back to Home',
                                  style: GoogleFonts.nunito(
                                    color: _darkText,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 300,
                                ),
                                child: ClaySquishButton(
                                  label: "Send to Messenger",
                                  primaryColor: const Color(0xFF0084FF),
                                  icon: Icons.send_rounded,
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    context.go('/');
                                    if (await canLaunchUrl(
                                      Uri.parse(messengerUrl),
                                    )) {
                                      await launchUrl(Uri.parse(messengerUrl));
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ); // FIXED: Dito natin inayos yung sobrang bracket.
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e', style: GoogleFonts.dmSans())),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  PreferredSizeWidget _buildGlassAppBar(CartProvider cart, bool isMobile) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(100),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 20 : 40,
              vertical: 10,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6)),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 22 : 28,
                        letterSpacing: -1,
                      ),
                      children: [
                        TextSpan(
                          text: 'VN BRIGADE ',
                          style: TextStyle(color: _darkText),
                        ),
                        TextSpan(
                          text: 'GROCERIES',
                          style: TextStyle(color: _primaryViolet),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildAppBarIcon(
                        Icons.home_rounded,
                        0,
                        () => context.go('/'),
                      ),
                      const SizedBox(width: 16),
                      _buildAppBarIcon(
                        Icons.person_rounded,
                        0,
                        () => context.go('/orders'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBarIcon(IconData icon, int badgeCount, VoidCallback onTap) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _clayCardShadow,
            ),
            child: Icon(icon, color: _darkText, size: 24),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _hotPink,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _hotPink.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                '$badgeCount',
                style: GoogleFonts.nunito(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isPhone = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAE5F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 2),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : TextInputType.text,
        validator: (v) => v!.isEmpty ? 'Required field' : null,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          color: _darkText,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: _primaryViolet, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          labelStyle: GoogleFonts.dmSans(color: _mutedText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final total = cartProvider.totalAmount;
    final isDesktop = MediaQuery.of(context).size.width > 900;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _canvas,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(cartProvider, isMobile),
      body: Stack(
        children: [
          // CLAYMORPHISM BACKGROUND BLOBS
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              height: 400,
              width: 400,
              decoration: BoxDecoration(
                color: _secondaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            left: -100,
            child: Container(
              height: 500,
              width: 500,
              decoration: BoxDecoration(
                color: _primaryVioletLight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),

          cartProvider.items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: _clayCardShadow,
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 80,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      const SizedBox(height: 40),
                      Text(
                        'Your cart is feeling light',
                        style: GoogleFonts.nunito(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Looks like you haven\'t added anything yet.',
                        style: GoogleFonts.dmSans(
                          color: _mutedText,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 48),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 300),
                        child: ClaySquishButton(
                          label: "Start Shopping",
                          primaryColor: _primaryViolet,
                          onPressed: () => context.go('/'),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      SizedBox(height: isMobile ? 120 : 140),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16.0 : 40.0,
                          vertical: 24.0,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1400),
                            child: isDesktop
                                ? Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        flex: 7,
                                        child: _buildLeftColumn(
                                          cartProvider,
                                          isMobile,
                                        ),
                                      ),
                                      const SizedBox(width: 48),
                                      Expanded(
                                        flex: 5,
                                        child: _buildRightColumn(
                                          cartProvider,
                                          total,
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      _buildLeftColumn(cartProvider, isMobile),
                                      const SizedBox(height: 40),
                                      _buildRightColumn(cartProvider, total),
                                    ],
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 80),

                      // --- ADDED PROFESSIONAL CLAYMORPHISM FOOTER ---
                      _buildProfessionalFooter(isMobile),
                    ],
                  ),
                ),
        ],
      ),
    );
  }

  // PROFESSIONAL FOOTER WIDGET
  Widget _buildProfessionalFooter(bool isMobile) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 80,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(48)),
        boxShadow: _clayCardShadow,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Flex(
          direction: isMobile ? Axis.vertical : Axis.horizontal,
          crossAxisAlignment: isMobile
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // BRANDING COLUMN
            Expanded(
              flex: isMobile ? 0 : 1,
              child: Column(
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: isMobile ? 24 : 32,
                        letterSpacing: -1,
                      ),
                      children: [
                        TextSpan(
                          text: 'VN BRIGADE\n',
                          style: TextStyle(color: _darkText),
                        ),
                        TextSpan(
                          text: 'GROCERIES ',
                          style: TextStyle(color: _primaryViolet),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Your premium destination for fresh, high-quality daily essentials. Serving the community with care and excellence.",
                    textAlign: isMobile ? TextAlign.center : TextAlign.left,
                    style: GoogleFonts.dmSans(
                      color: _mutedText,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: isMobile
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
                    children: [
                      _buildSocialIcon(Icons.facebook_rounded),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.camera_alt_rounded),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.send_rounded),
                    ],
                  ),
                  if (isMobile) const SizedBox(height: 40),
                ],
              ),
            ),

            if (!isMobile) const SizedBox(width: 60),

            // CONTACT US COLUMN
            Expanded(
              flex: isMobile ? 0 : 1,
              child: Container(
                padding: EdgeInsets.all(isMobile ? 24 : 32),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE5F0), // Recessed clay look
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.03),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: isMobile
                      ? CrossAxisAlignment.center
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Contact Us",
                      style: GoogleFonts.nunito(
                        color: _darkText,
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildContactRow(Icons.phone_rounded, "09765590309"),
                    const SizedBox(height: 16),
                    _buildContactRow(
                      Icons.location_on_rounded,
                      "Dasmariñas, Cavite, PH",
                    ),
                    const SizedBox(height: 16),
                    _buildContactRow(
                      Icons.email_rounded,
                      "support@vnbrigade.com",
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFA096B4).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(4, 4),
          ),
          const BoxShadow(
            color: Colors.white,
            blurRadius: 12,
            offset: Offset(-4, -4),
          ),
        ],
      ),
      child: Icon(icon, color: _primaryViolet, size: 20),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(2, 2),
              ),
            ],
          ),
          child: Icon(icon, color: _primaryViolet, size: 16),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            text,
            style: GoogleFonts.dmSans(
              color: _darkText,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeftColumn(CartProvider cartProvider, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "My Cart (${cartProvider.items.length} items)",
          style: GoogleFonts.nunito(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _darkText,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            boxShadow: _clayCardShadow,
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.all(32),
            physics: const NeverScrollableScrollPhysics(),
            itemCount: cartProvider.items.length,
            separatorBuilder: (_, __) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Divider(color: Colors.grey.shade200, thickness: 2),
            ),
            itemBuilder: (ctx, i) {
              final item = cartProvider.items.values.toList()[i];
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE5F0),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: item.product.imageUrl.isNotEmpty
                        ? Image.network(
                            item.product.imageUrl,
                            fit: BoxFit.contain,
                          )
                        : const Icon(Icons.image, color: Colors.grey),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.product.name,
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _darkText,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _secondaryOrange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.priceType.toUpperCase(),
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: _secondaryOrange,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '₱${item.price.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: _primaryViolet,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isMobile) const SizedBox(width: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () => cartProvider.removeItem(
                                item.product.id,
                                item.priceType,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEAE5F0),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Text(
                                '${item.quantity}',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () => cartProvider.addItem(
                                item.product,
                                item.priceType,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _primaryViolet,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '₱${(item.price * item.quantity).toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 64),
        Text(
          "Delivery Details",
          style: GoogleFonts.nunito(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: _darkText,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            boxShadow: _clayCardShadow,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildModernTextField(
                        _nameController,
                        'Full Name',
                        Icons.person_outline_rounded,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _buildModernTextField(
                        _phoneController,
                        'Phone Number',
                        Icons.phone_outlined,
                        isPhone: true,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildModernTextField(
                  _addressController,
                  'Complete Address (Street, Brgy, City)',
                  Icons.location_on_outlined,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(CartProvider cartProvider, double total) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            boxShadow: _clayCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Have a coupon?",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                  color: _darkText,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE5F0),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.03),
                          width: 2,
                        ),
                      ),
                      child: TextField(
                        controller: _couponController,
                        style: GoogleFonts.dmSans(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          hintText: "Enter Code",
                          hintStyle: GoogleFonts.dmSans(
                            color: _mutedText,
                            fontWeight: FontWeight.normal,
                          ),
                          prefixIcon: Icon(
                            Icons.local_offer_rounded,
                            size: 20,
                            color: _primaryViolet,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 120,
                    child: ClaySquishButton(
                      label: "Apply",
                      primaryColor: _darkText,
                      onPressed: () => _applyCoupon(cartProvider),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            boxShadow: _clayCardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Order Summary",
                style: GoogleFonts.nunito(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: _darkText,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Subtotal",
                    style: GoogleFonts.dmSans(color: _mutedText, fontSize: 16),
                  ),
                  Text(
                    "₱${total.toStringAsFixed(2)}",
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: _darkText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Shipping",
                    style: GoogleFonts.dmSans(color: _mutedText, fontSize: 16),
                  ),
                  Text(
                    "Free",
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: const Color(0xFF10B981),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Divider(height: 2, color: Colors.grey.shade200, thickness: 2),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Total Payment",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: _darkText,
                    ),
                  ),
                  Text(
                    "₱${total.toStringAsFixed(2)}",
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 36,
                      color: _primaryViolet,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              InkWell(
                onTap: _showQRDialog,
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0084FF).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF0084FF).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.qr_code_scanner_rounded,
                          color: Color(0xFF0084FF),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        "Pay via GCash QR",
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF0084FF),
                          fontSize: 16,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Color(0xFF0084FF),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ClaySquishButton(
                label: "Place Order",
                primaryColor: _primaryViolet,
                isLoading: _isSubmitting,
                onPressed: () => _submitOrder(cartProvider),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// --- CLAY SQUISH BUTTON WIDGET ---
class ClaySquishButton extends StatefulWidget {
  final String label;
  final Color primaryColor;
  final bool isLoading;
  final IconData? icon;
  final VoidCallback onPressed;

  const ClaySquishButton({
    super.key,
    required this.label,
    required this.primaryColor,
    this.isLoading = false,
    this.icon,
    required this.onPressed,
  });

  @override
  State<ClaySquishButton> createState() => _ClaySquishButtonState();
}

class _ClaySquishButtonState extends State<ClaySquishButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        if (!widget.isLoading) widget.onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 64,
        width: double.infinity,
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _isPressed ? 4 : 0, 0)
          ..scale(_isPressed ? 0.95 : 1.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [widget.primaryColor.withOpacity(0.8), widget.primaryColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: _isPressed
              ? [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: widget.primaryColor.withOpacity(0.4),
                    blurRadius: 24,
                    offset: const Offset(12, 12),
                  ),
                  BoxShadow(
                    color: Colors.white.withOpacity(0.5),
                    blurRadius: 16,
                    offset: const Offset(-8, -8),
                  ),
                ],
        ),
        child: Center(
          child: widget.isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.nunito(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
