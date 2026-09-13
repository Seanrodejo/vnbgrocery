import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';

enum AdminTab { analytics, orders, products }

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<Order> _orders = [];
  List<Product> _products = [];
  bool _isLoadingOrders = true;
  bool _isLoadingProducts = true;
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  bool _obscureAdminPassword = true;

  AdminTab _currentTab = AdminTab.analytics;

  final TextEditingController _orderSearchController = TextEditingController();
  final TextEditingController _productSearchController =
      TextEditingController();
  String _orderSearchQuery = '';
  String _productSearchQuery = '';

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

  final List<String> _categories = [
    'Refreshments/Drinks',
    'Food/Snacks',
    'Condiments',
    'Coffee/Milk',
    'Personal Hygiene',
    'Medicine',
    'Insecticide',
    'Cleaning',
    'Liquor',
    'Cigar',
    'Rice',
    'Chocolates',
  ];

  @override
  void initState() {
    super.initState();
    _orderSearchController.addListener(() {
      setState(
        () => _orderSearchQuery = _orderSearchController.text.toLowerCase(),
      );
    });
    _productSearchController.addListener(() {
      setState(
        () => _productSearchQuery = _productSearchController.text.toLowerCase(),
      );
    });
  }

  void _authenticate(String password) {
    if (password == 'admin123') {
      setState(() => _isAuthenticated = true);
      _loadOrders();
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Invalid password',
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _orderSearchController.dispose();
    _productSearchController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    try {
      final orders = await _firebaseService.getOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoadingOrders = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingOrders = false);
    }
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoadingProducts = true);
    try {
      final products = await _firebaseService.getProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _isLoadingProducts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingProducts = false);
    }
  }

  Future<void> _updateStatus(String orderId, String status) async {
    try {
      await _firebaseService.updateOrderStatus(orderId, status);
      _loadOrders();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order status updated to ${status.toUpperCase()}',
              style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  double get _totalRevenue {
    return _orders
        .where((o) => o.status != 'cancelled')
        .fold(0.0, (sum, order) => sum + order.total);
  }

  Map<String, double> get _salesByCategory {
    Map<String, double> categorySales = {};
    Map<String, String> productCategories = {
      for (var p in _products) p.id: p.category,
    };
    for (var order in _orders) {
      if (order.status == 'cancelled') continue;
      for (var item in order.items) {
        String category = productCategories[item.productId] ?? 'Others';
        double amount = item.price * item.quantity;
        categorySales[category] = (categorySales[category] ?? 0) + amount;
      }
    }
    return categorySales;
  }

  List<double> get _weeklySales {
    List<double> sales = List.filled(7, 0.0);
    final now = DateTime.now();
    for (var order in _orders) {
      if (order.status == 'cancelled') continue;
      final difference = now.difference(order.createdAt).inDays;
      if (difference >= 0 && difference < 7) {
        sales[difference] += order.total;
      }
    }
    return sales.reversed.toList();
  }

  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        allowMultiple: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName =
            '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child(
          'product_images/$fileName',
        );

        if (file.bytes != null) {
          String extension = file.extension ?? 'jpeg';
          final metadata = SettableMetadata(contentType: 'image/$extension');
          await ref.putData(file.bytes!, metadata);
        }

        final downloadUrl = await ref.getDownloadURL();
        controller.text = downloadUrl;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Image uploaded successfully!',
                style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error uploading image: $e',
            style: GoogleFonts.dmSans(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDetailsDialog(Order order) {
    String userType = order.userId == 'guest'
        ? 'Guest User'
        : 'Registered Member';

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(40),
          ),
          backgroundColor: Colors.white.withOpacity(0.95),
          surfaceTintColor: Colors.transparent,
          contentPadding: const EdgeInsets.all(40),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Order: #${order.referenceId.split('-').last}',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: _darkText,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
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
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SizedBox(
            width: 700,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F1FA),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.03),
                        width: 2,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: order.userId == 'guest'
                                ? Colors.grey.shade200
                                : _primaryViolet.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            userType.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: order.userId == 'guest'
                                  ? _mutedText
                                  : _primaryViolet,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        _buildDetailRow(
                          Icons.person_outline,
                          'Customer',
                          order.customerName,
                        ),
                        _buildDetailRow(
                          Icons.phone_outlined,
                          'Phone',
                          order.customerPhone,
                        ),
                        _buildDetailRow(
                          Icons.location_on_outlined,
                          'Address',
                          order.customerAddress,
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Divider(),
                        ),
                        _buildDetailRow(
                          Icons.calendar_today_outlined,
                          'Date',
                          DateFormat(
                            'MMM d, yyyy • h:mm a',
                          ).format(order.createdAt),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    'Items Ordered',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      color: _darkText,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200, width: 2),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                          Colors.grey.shade50,
                        ),
                        dataRowMaxHeight: 80,
                        columns: [
                          DataColumn(
                            label: Text(
                              'Product',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: _mutedText,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Price',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: _mutedText,
                              ),
                            ),
                          ),
                          DataColumn(
                            label: Text(
                              'Subtotal',
                              style: GoogleFonts.nunito(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: _mutedText,
                              ),
                            ),
                          ),
                        ],
                        rows: order.items.map((item) {
                          final subtotal = item.price * item.quantity;
                          return DataRow(
                            cells: [
                              DataCell(
                                Text(
                                  '${item.productName} (${item.priceType}) x${item.quantity}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '₱${item.price.toStringAsFixed(2)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 15,
                                    color: _mutedText,
                                  ),
                                ),
                              ),
                              DataCell(
                                Text(
                                  '₱${subtotal.toStringAsFixed(2)}',
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 16,
                                    color: _darkText,
                                  ),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Amount',
                        style: GoogleFonts.nunito(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                        ),
                      ),
                      Text(
                        '₱${order.total.toStringAsFixed(2)}',
                        style: GoogleFonts.nunito(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: _primaryViolet,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Divider(thickness: 2),
                  ),

                  Text(
                    'Update Order Status',
                    style: GoogleFonts.nunito(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      color: _mutedText,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE5F0),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.03),
                        width: 2,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: order.status,
                        isExpanded: true,
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: _primaryViolet,
                          size: 28,
                        ),
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        items:
                            [
                                  'pending',
                                  'confirmed',
                                  'shipped',
                                  'delivered',
                                  'cancelled',
                                ]
                                .map(
                                  (status) => DropdownMenuItem(
                                    value: status,
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: status == 'delivered'
                                            ? const Color(0xFF10B981)
                                            : status == 'cancelled'
                                            ? Colors.red
                                            : status == 'pending'
                                            ? _secondaryOrange
                                            : _primaryViolet,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (newStatus) {
                          if (newStatus != null)
                            _updateStatus(order.id, newStatus);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.all(40),
          actions: [
            TextButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(32),
                    ),
                    title: Text(
                      'Delete Order',
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: _darkText,
                      ),
                    ),
                    content: Text(
                      'Are you sure? This cannot be undone.',
                      style: GoogleFonts.dmSans(fontSize: 16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.bold,
                            color: _mutedText,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: Text(
                          'Delete',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await _firebaseService.deleteOrder(order.id);
                  if (mounted) {
                    Navigator.pop(context);
                    _loadOrders();
                  }
                }
              },
              child: Text(
                'Delete Order',
                style: GoogleFonts.nunito(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 16),
            SizedBox(
              width: 140,
              child: ClaySquishButton(
                label: "Close",
                primaryColor: _primaryViolet,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: _primaryViolet),
          const SizedBox(width: 16),
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: _mutedText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.dmSans(
                color: _darkText,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductDialog([Product? product]) {
    final nameController = TextEditingController(text: product?.name);
    final marketPriceController = TextEditingController(
      text: product?.retailPrice.toString(),
    );
    final vnbPriceController = TextEditingController(
      text: product?.wholesalePrice.toString(),
    );
    final descriptionController = TextEditingController(
      text: product?.description,
    );
    final imageUrlController = TextEditingController(text: product?.imageUrl);
    final couponCodeController = TextEditingController(
      text: product?.couponCode,
    );
    final discountAmountController = TextEditingController(
      text: product?.discountAmount.toString() ?? '0.0',
    );

    String selectedCategory = product?.category ?? _categories.first;
    if (selectedCategory.isEmpty || !_categories.contains(selectedCategory))
      selectedCategory = _categories.first;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(40),
              ),
              surfaceTintColor: Colors.transparent,
              backgroundColor: Colors.white.withOpacity(0.95),
              title: Text(
                product == null ? 'Add New Product' : 'Edit Product',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 28,
                  color: _darkText,
                  letterSpacing: -0.5,
                ),
              ),
              content: SizedBox(
                width: 700,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 24),
                      _buildModernTextField(
                        nameController,
                        'Product Name',
                        Icons.inventory_2_rounded,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              marketPriceController,
                              'Retail Price',
                              Icons.sell_rounded,
                              isNumber: true,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildModernTextField(
                              vnbPriceController,
                              'Wholesale Price',
                              Icons.storefront_rounded,
                              isNumber: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildModernTextField(
                        descriptionController,
                        'Description',
                        Icons.description_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE5F0),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.03),
                            width: 2,
                          ),
                        ),
                        child: TextField(
                          controller: imageUrlController,
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Image URL',
                            labelStyle: GoogleFonts.dmSans(color: _mutedText),
                            prefixIcon: Icon(
                              Icons.link_rounded,
                              color: _primaryViolet,
                              size: 22,
                            ),
                            suffixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: IconButton(
                                icon: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _primaryVioletLight.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.file_upload_rounded,
                                    color: _primaryViolet,
                                  ),
                                ),
                                onPressed: () =>
                                    _pickAndUploadImage(imageUrlController),
                              ),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE5F0),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.03),
                            width: 2,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButtonFormField<String>(
                            value: selectedCategory,
                            decoration: InputDecoration(
                              labelText: 'Category',
                              prefixIcon: Icon(
                                Icons.category_rounded,
                                color: _primaryViolet,
                              ),
                              border: InputBorder.none,
                              labelStyle: GoogleFonts.dmSans(color: _mutedText),
                            ),
                            items: _categories
                                .map(
                                  (String category) => DropdownMenuItem<String>(
                                    value: category,
                                    child: Text(
                                      category,
                                      style: GoogleFonts.dmSans(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (String? newValue) {
                              setDialogState(() {
                                selectedCategory = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Promo Settings",
                          style: GoogleFonts.nunito(
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                            color: _darkText,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: _secondaryOrange.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(32),
                          border: Border.all(
                            color: _secondaryOrange.withOpacity(0.2),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildModernTextField(
                              couponCodeController,
                              'Coupon Code (e.g. SALE10)',
                              Icons.local_offer_rounded,
                            ),
                            const SizedBox(height: 20),
                            _buildModernTextField(
                              discountAmountController,
                              'Discount Amount (₱)',
                              Icons.money_off_rounded,
                              isNumber: true,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actionsPadding: const EdgeInsets.all(40),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.nunito(
                      color: _mutedText,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 200,
                  child: ClaySquishButton(
                    label: "Save Product",
                    primaryColor: _primaryViolet,
                    onPressed: () async {
                      try {
                        final name = nameController.text.trim();
                        final marketPrice = double.tryParse(
                          marketPriceController.text.trim(),
                        );
                        final vnbPrice = double.tryParse(
                          vnbPriceController.text.trim(),
                        );
                        final couponCode = couponCodeController.text.trim();
                        final discountAmount =
                            double.tryParse(
                              discountAmountController.text.trim(),
                            ) ??
                            0.0;

                        if (name.isEmpty ||
                            marketPrice == null ||
                            vnbPrice == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Please fill all required fields',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: Colors.redAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          return;
                        }

                        final newProduct = Product(
                          id: product?.id ?? '',
                          name: name,
                          retailPrice: marketPrice,
                          wholesalePrice: vnbPrice,
                          description: descriptionController.text.trim(),
                          imageUrl: imageUrlController.text.trim(),
                          category: selectedCategory,
                          couponCode: couponCode,
                          discountAmount: discountAmount,
                        );

                        if (product == null) {
                          await _firebaseService.addProduct(newProduct);
                        } else {
                          await _firebaseService.updateProduct(newProduct);
                        }

                        if (mounted) {
                          Navigator.of(context).pop();
                          _loadProducts();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                product == null
                                    ? 'Product added successfully!'
                                    : 'Product updated successfully!',
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              backgroundColor: const Color(0xFF10B981),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Error: $e',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFEAE5F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 2),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        maxLines: maxLines,
        style: GoogleFonts.dmSans(
          fontSize: 16,
          color: _darkText,
          fontWeight: FontWeight.bold,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.dmSans(color: _mutedText),
          prefixIcon: Icon(icon, color: _primaryViolet, size: 22),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final weeklySales = _weeklySales;
    final categorySales = _salesByCategory;

    final List<Color> pieColors = [
      _primaryViolet,
      _secondaryOrange,
      _hotPink,
      const Color(0xFF0EA5E9),
      const Color(0xFF10B981),
      Colors.amber.shade400,
      Colors.indigo.shade400,
      Colors.teal.shade300,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(48.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryVioletLight, _primaryViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryViolet.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(10, 10),
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        blurRadius: 20,
                        offset: Offset(-10, -10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Total Revenue',
                              style: GoogleFonts.nunito(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '₱${_totalRevenue.toStringAsFixed(2)}',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 40),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_secondaryOrange, const Color(0xFFE87A15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: _secondaryOrange.withOpacity(0.4),
                        blurRadius: 30,
                        offset: const Offset(10, 10),
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        blurRadius: 20,
                        offset: Offset(-10, -10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.shopping_bag_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              'Total Orders',
                              style: GoogleFonts.nunito(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          '${_orders.length}',
                          style: GoogleFonts.nunito(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 64),
          Text(
            'Last 7 Days Sales',
            style: GoogleFonts.nunito(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _darkText,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(48),
              boxShadow: _clayCardShadow,
            ),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 2),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dayIndex = 6 - value.toInt();
                        final date = DateTime.now().subtract(
                          Duration(days: dayIndex),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Text(
                            DateFormat('E').format(date),
                            style: GoogleFonts.nunito(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: _mutedText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklySales.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [
                      BarChartRodData(
                        toY: e.value,
                        color: _primaryViolet,
                        width: 32,
                        borderRadius: BorderRadius.circular(12),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY:
                              weeklySales.reduce((a, b) => a > b ? a : b) * 1.2,
                          color: const Color(0xFFF4F1FA),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 64),
          Text(
            'Sales by Category',
            style: GoogleFonts.nunito(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: _darkText,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            height: 400,
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(48),
              boxShadow: _clayCardShadow,
            ),
            child: categorySales.isEmpty
                ? Center(
                    child: Text(
                      "No Sales Data Yet",
                      style: GoogleFonts.dmSans(
                        color: _mutedText,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : Row(
                    children: [
                      Expanded(
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 6,
                            centerSpaceRadius: 80,
                            sections: categorySales.entries.map((e) {
                              final isLarge = e.value > 500;
                              int index = categorySales.keys.toList().indexOf(
                                e.key,
                              );
                              return PieChartSectionData(
                                color: pieColors[index % pieColors.length],
                                value: e.value,
                                title: '',
                                radius: isLarge ? 90 : 80,
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          shrinkWrap: true,
                          children: categorySales.entries.map((e) {
                            int index = categorySales.keys.toList().indexOf(
                              e.key,
                            );
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color:
                                          pieColors[index % pieColors.length],
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              pieColors[index %
                                                      pieColors.length]
                                                  .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      e.key,
                                      style: GoogleFonts.dmSans(
                                        fontSize: 16,
                                        color: _darkText,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '₱${e.value.toStringAsFixed(0)}',
                                    style: GoogleFonts.nunito(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: _darkText,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAuthenticated) {
      return Scaffold(
        backgroundColor: _canvas,
        body: Stack(
          children: [
            Positioned(
              top: -100,
              left: -100,
              child: Container(
                width: 500,
                height: 500,
                decoration: BoxDecoration(
                  color: _primaryVioletLight.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              right: -50,
              child: Container(
                width: 600,
                height: 600,
                decoration: BoxDecoration(
                  color: _hotPink.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: Container(color: Colors.transparent),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(48),
                    boxShadow: _clayCardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(48),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Padding(
                        padding: const EdgeInsets.all(48.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _primaryViolet.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.admin_panel_settings_rounded,
                                size: 64,
                                color: _primaryViolet,
                              ),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Admin Access',
                              style: GoogleFonts.nunito(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: _darkText,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Secure login required to manage the store.',
                              style: GoogleFonts.dmSans(
                                color: _mutedText,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 48),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAE5F0),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.03),
                                  width: 2,
                                ),
                              ),
                              child: TextField(
                                controller: _passwordController,
                                obscureText: _obscureAdminPassword,
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  color: _darkText,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Admin Password',
                                  labelStyle: GoogleFonts.dmSans(
                                    color: _mutedText,
                                  ),
                                  prefixIcon: Icon(
                                    Icons.lock_rounded,
                                    color: _primaryViolet,
                                    size: 22,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureAdminPassword
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: _mutedText,
                                      size: 22,
                                    ),
                                    onPressed: () => setState(
                                      () => _obscureAdminPassword =
                                          !_obscureAdminPassword,
                                    ),
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 20,
                                  ),
                                ),
                                onSubmitted: _authenticate,
                              ),
                            ),
                            const SizedBox(height: 40),
                            ClaySquishButton(
                              label: "Login Securely",
                              primaryColor: _primaryViolet,
                              onPressed: () =>
                                  _authenticate(_passwordController.text),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final filteredProducts = _products.where((product) {
      return product.name.toLowerCase().contains(_productSearchQuery);
    }).toList();
    final filteredOrders = _orders.where((order) {
      return order.referenceId.toLowerCase().contains(_orderSearchQuery);
    }).toList();

    return Scaffold(
      backgroundColor: _canvas,
      body: Row(
        children: [
          // --- SAAS SIDEBAR ---
          Container(
            width: 320,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 30,
                  offset: const Offset(10, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 48,
                    horizontal: 32,
                  ),
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        letterSpacing: -0.5,
                      ),
                      children: [
                        TextSpan(
                          text: 'VNB ',
                          style: TextStyle(color: _secondaryOrange),
                        ),
                        TextSpan(
                          text: 'ADMIN',
                          style: TextStyle(color: _primaryViolet),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildSidebarItem(
                  Icons.analytics_rounded,
                  'Dashboard Analytics',
                  AdminTab.analytics,
                ),
                _buildSidebarItem(
                  Icons.receipt_long_rounded,
                  'Manage Orders',
                  AdminTab.orders,
                ),
                _buildSidebarItem(
                  Icons.inventory_2_rounded,
                  'Product Inventory',
                  AdminTab.products,
                ),
                const Spacer(),
                const Divider(),
                InkWell(
                  onTap: () {
                    setState(() => _isAuthenticated = false);
                    _passwordController.clear();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, color: _hotPink, size: 24),
                        const SizedBox(width: 16),
                        Text(
                          "Log Out",
                          style: GoogleFonts.dmSans(
                            color: _hotPink,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- MAIN CONTENT AREA ---
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  decoration: BoxDecoration(
                    color: _canvas,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.black.withOpacity(0.05),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _currentTab == AdminTab.analytics
                            ? 'Analytics Overview'
                            : _currentTab == AdminTab.orders
                            ? 'Order Management'
                            : 'Product Inventory',
                        style: GoogleFonts.nunito(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: _darkText,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: _clayCardShadow,
                        ),
                        child: Icon(
                          Icons.admin_panel_settings_rounded,
                          color: _primaryViolet,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Stack(
                    children: [
                      Positioned(
                        top: -100,
                        right: -100,
                        child: Container(
                          width: 500,
                          height: 500,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0EA5E9).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                          child: Container(color: Colors.transparent),
                        ),
                      ),

                      _currentTab == AdminTab.analytics
                          ? (_isLoadingOrders || _isLoadingProducts
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryViolet,
                                    ),
                                  )
                                : _buildAnalyticsTab())
                          : _currentTab == AdminTab.orders
                          ? (_isLoadingOrders
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryViolet,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(48.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEAE5F0),
                                            borderRadius: BorderRadius.circular(
                                              24,
                                            ),
                                            border: Border.all(
                                              color: Colors.black.withOpacity(
                                                0.03,
                                              ),
                                              width: 2,
                                            ),
                                          ),
                                          child: TextField(
                                            controller: _orderSearchController,
                                            style: GoogleFonts.dmSans(
                                              fontSize: 16,
                                              color: _darkText,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            decoration: InputDecoration(
                                              hintText: 'Search by Order ID...',
                                              hintStyle: GoogleFonts.dmSans(
                                                color: _mutedText,
                                              ),
                                              prefixIcon: Icon(
                                                Icons.search_rounded,
                                                color: _primaryViolet,
                                                size: 24,
                                              ),
                                              border: InputBorder.none,
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 24,
                                                    vertical: 20,
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 48,
                                          ),
                                          itemCount: filteredOrders.length,
                                          itemBuilder: (context, index) {
                                            final order = filteredOrders[index];
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 24,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.85,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                                boxShadow: _clayCardShadow,
                                              ),
                                              child: InkWell(
                                                onTap: () =>
                                                    _showOrderDetailsDialog(
                                                      order,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                                child: Padding(
                                                  padding: const EdgeInsets.all(
                                                    32.0,
                                                  ),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              20,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color:
                                                              order.status ==
                                                                  'delivered'
                                                              ? Colors
                                                                    .green
                                                                    .shade50
                                                              : order.status ==
                                                                    'cancelled'
                                                              ? Colors
                                                                    .red
                                                                    .shade50
                                                              : _secondaryOrange
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                        child: Icon(
                                                          order.status ==
                                                                  'delivered'
                                                              ? Icons
                                                                    .check_circle_outline
                                                              : order.status ==
                                                                    'cancelled'
                                                              ? Icons
                                                                    .cancel_outlined
                                                              : Icons
                                                                    .pending_actions,
                                                          color:
                                                              order.status ==
                                                                  'delivered'
                                                              ? Colors.green
                                                              : order.status ==
                                                                    'cancelled'
                                                              ? Colors.red
                                                              : _secondaryOrange,
                                                          size: 32,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 24),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              '#${order.referenceId.split('-').last}',
                                                              style: GoogleFonts.nunito(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                fontSize: 22,
                                                                color:
                                                                    _darkText,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 4,
                                                            ),
                                                            Text(
                                                              order
                                                                  .customerName,
                                                              style: GoogleFonts.dmSans(
                                                                color:
                                                                    _mutedText,
                                                                fontSize: 16,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .end,
                                                        children: [
                                                          Text(
                                                            '₱${order.total.toStringAsFixed(2)}',
                                                            style:
                                                                GoogleFonts.nunito(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  fontSize: 24,
                                                                  color:
                                                                      _darkText,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 12,
                                                          ),
                                                          Container(
                                                            padding:
                                                                const EdgeInsets.symmetric(
                                                                  horizontal:
                                                                      16,
                                                                  vertical: 6,
                                                                ),
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  const Color(
                                                                    0xFFF4F1FA,
                                                                  ),
                                                              borderRadius:
                                                                  BorderRadius.circular(
                                                                    12,
                                                                  ),
                                                            ),
                                                            child: Text(
                                                              order.status
                                                                  .toUpperCase(),
                                                              style: GoogleFonts.nunito(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w900,
                                                                color:
                                                                    _primaryViolet,
                                                                letterSpacing:
                                                                    1.0,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(width: 32),
                                                      Icon(
                                                        Icons
                                                            .arrow_forward_ios_rounded,
                                                        size: 20,
                                                        color: Colors
                                                            .grey
                                                            .shade400,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ))
                          : (_isLoadingProducts
                                ? Center(
                                    child: CircularProgressIndicator(
                                      color: _primaryViolet,
                                    ),
                                  )
                                : Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(48.0),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: const Color(
                                                    0xFFEAE5F0,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(24),
                                                  border: Border.all(
                                                    color: Colors.black
                                                        .withOpacity(0.03),
                                                    width: 2,
                                                  ),
                                                ),
                                                child: TextField(
                                                  controller:
                                                      _productSearchController,
                                                  style: GoogleFonts.dmSans(
                                                    fontSize: 16,
                                                    color: _darkText,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Search Inventory...',
                                                    hintStyle:
                                                        GoogleFonts.dmSans(
                                                          color: _mutedText,
                                                        ),
                                                    prefixIcon: Icon(
                                                      Icons.search_rounded,
                                                      color: _primaryViolet,
                                                      size: 24,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 24,
                                                          vertical: 20,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 32),
                                            SizedBox(
                                              width: 240,
                                              child: ClaySquishButton(
                                                label: "Add Product",
                                                primaryColor: _primaryViolet,
                                                icon: Icons.add_rounded,
                                                onPressed: () =>
                                                    _showProductDialog(),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: ListView.builder(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 48,
                                          ),
                                          itemCount: filteredProducts.length,
                                          itemBuilder: (context, index) {
                                            final product =
                                                filteredProducts[index];
                                            return Container(
                                              margin: const EdgeInsets.only(
                                                bottom: 24,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                  0.85,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(32),
                                                boxShadow: _clayCardShadow,
                                              ),
                                              child: Padding(
                                                padding: const EdgeInsets.all(
                                                  24.0,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Container(
                                                      width: 96,
                                                      height: 96,
                                                      decoration: BoxDecoration(
                                                        color: const Color(
                                                          0xFFEAE5F0,
                                                        ),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                      ),
                                                      child: ClipRRect(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              24,
                                                            ),
                                                        child:
                                                            product
                                                                .imageUrl
                                                                .isNotEmpty
                                                            ? Image.network(
                                                                product
                                                                    .imageUrl,
                                                                fit: BoxFit
                                                                    .cover,
                                                                errorBuilder:
                                                                    (
                                                                      c,
                                                                      e,
                                                                      s,
                                                                    ) => const Icon(
                                                                      Icons
                                                                          .image,
                                                                      color: Colors
                                                                          .grey,
                                                                    ),
                                                              )
                                                            : const Icon(
                                                                Icons.image,
                                                                color:
                                                                    Colors.grey,
                                                              ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 24),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            product.name,
                                                            style:
                                                                GoogleFonts.nunito(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w900,
                                                                  fontSize: 20,
                                                                  color:
                                                                      _darkText,
                                                                ),
                                                          ),
                                                          const SizedBox(
                                                            height: 6,
                                                          ),
                                                          Text(
                                                            '${product.category} • ₱${product.retailPrice.toStringAsFixed(2)}',
                                                            style:
                                                                GoogleFonts.dmSans(
                                                                  color:
                                                                      _mutedText,
                                                                  fontSize: 15,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                          ),
                                                          if (product
                                                              .couponCode
                                                              .isNotEmpty)
                                                            Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    top: 8.0,
                                                                  ),
                                                              child: Text(
                                                                "Promo: ${product.couponCode} (-₱${product.discountAmount.toStringAsFixed(0)})",
                                                                style: GoogleFonts.dmSans(
                                                                  color: const Color(
                                                                    0xFF10B981,
                                                                  ),
                                                                  fontSize: 13,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        IconButton(
                                                          icon: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .blue
                                                                      .shade50,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .edit_rounded,
                                                              color: Colors
                                                                  .blue
                                                                  .shade700,
                                                              size: 24,
                                                            ),
                                                          ),
                                                          onPressed: () =>
                                                              _showProductDialog(
                                                                product,
                                                              ),
                                                        ),
                                                        const SizedBox(
                                                          width: 16,
                                                        ),
                                                        IconButton(
                                                          icon: Container(
                                                            padding:
                                                                const EdgeInsets.all(
                                                                  12,
                                                                ),
                                                            decoration:
                                                                BoxDecoration(
                                                                  color: Colors
                                                                      .red
                                                                      .shade50,
                                                                  shape: BoxShape
                                                                      .circle,
                                                                ),
                                                            child: Icon(
                                                              Icons
                                                                  .delete_outline_rounded,
                                                              color: Colors
                                                                  .red
                                                                  .shade700,
                                                              size: 24,
                                                            ),
                                                          ),
                                                          onPressed: () async {
                                                            final confirm = await showDialog<bool>(
                                                              context: context,
                                                              builder: (context) => AlertDialog(
                                                                shape: RoundedRectangleBorder(
                                                                  borderRadius:
                                                                      BorderRadius.circular(
                                                                        32,
                                                                      ),
                                                                ),
                                                                title: Text(
                                                                  'Delete Product',
                                                                  style: GoogleFonts.nunito(
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w900,
                                                                    fontSize:
                                                                        24,
                                                                  ),
                                                                ),
                                                                content: Text(
                                                                  'Delete ${product.name}?',
                                                                  style:
                                                                      GoogleFonts.dmSans(
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                ),
                                                                actions: [
                                                                  TextButton(
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                          context,
                                                                          false,
                                                                        ),
                                                                    child: Text(
                                                                      'Cancel',
                                                                      style: GoogleFonts.nunito(
                                                                        fontWeight:
                                                                            FontWeight.bold,
                                                                        color:
                                                                            _mutedText,
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  ElevatedButton(
                                                                    style: ElevatedButton.styleFrom(
                                                                      backgroundColor:
                                                                          Colors
                                                                              .redAccent,
                                                                      padding: const EdgeInsets.symmetric(
                                                                        horizontal:
                                                                            24,
                                                                        vertical:
                                                                            16,
                                                                      ),
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius:
                                                                            BorderRadius.circular(
                                                                              16,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    onPressed: () =>
                                                                        Navigator.pop(
                                                                          context,
                                                                          true,
                                                                        ),
                                                                    child: Text(
                                                                      'Delete',
                                                                      style: GoogleFonts.nunito(
                                                                        color: Colors
                                                                            .white,
                                                                        fontWeight:
                                                                            FontWeight.w900,
                                                                        fontSize:
                                                                            16,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                            if (confirm ==
                                                                true) {
                                                              try {
                                                                await _firebaseService
                                                                    .deleteProduct(
                                                                      product
                                                                          .id,
                                                                    );
                                                                _loadProducts();
                                                              } catch (e) {
                                                                if (mounted)
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    SnackBar(
                                                                      content: Text(
                                                                        'Error: $e',
                                                                      ),
                                                                    ),
                                                                  );
                                                              }
                                                            }
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData icon, String label, AdminTab tab) {
    final isActive = _currentTab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => setState(() => _currentTab = tab),
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: isActive ? _primaryViolet : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _primaryViolet.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : [],
          ),
          child: Row(
            children: [
              Icon(icon, size: 24, color: isActive ? Colors.white : _mutedText),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? Colors.white : _darkText,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
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
                      Icon(widget.icon, color: Colors.white, size: 24),
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
