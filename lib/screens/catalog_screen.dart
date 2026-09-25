import 'dart:ui';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../services/firebase_service.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  List<Product> _products = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  // CLAYMORPHISM COLORS (Candy Palette)
  final Color _canvas = const Color(0xFFF4F1FA);
  final Color _primaryViolet = const Color(0xFF7C3AED);
  final Color _primaryVioletLight = const Color(0xFFA78BFA);
  final Color _hotPink = const Color(0xFFDB2777);
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
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final products = await _firebaseService.getProducts(
        sortBy: 'name',
        ascending: true,
      );
      if (!mounted) return;
      final uniqueCategories = products
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      uniqueCategories.sort();
      setState(() {
        _products = products;
        _categories = ['All', ...uniqueCategories];
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showProductDetails(
    BuildContext context,
    Product product,
    bool isLoggedIn,
  ) {
    String selectedPriceType = 'retail';
    int quantity = 1;
    final ScrollController modalScrollController = ScrollController();
    bool showScrollNotice = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final bool isRetail = selectedPriceType == 'retail';
          final screenWidth = MediaQuery.of(context).size.width;
          final isMobile = screenWidth < 600;

          // TUNAY NA LOGIC: Price per piece or bundle na in-input ni admin imu-multiply sa quantity
          final double currentPrice = isRetail
              ? product.retailPrice
              : product.wholesalePrice;
          final double totalPrice = currentPrice * quantity;
          final double displayPrice = currentPrice;

          modalScrollController.addListener(() {
            if (modalScrollController.offset > 30 && showScrollNotice) {
              setModalState(() => showScrollNotice = false);
            } else if (modalScrollController.offset <= 30 &&
                !showScrollNotice) {
              setModalState(() => showScrollNotice = true);
            }
          });

          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              margin: EdgeInsets.only(top: isMobile ? 60 : 120),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.95),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(40),
                ),
                boxShadow: _clayCardShadow,
              ),
              child: Stack(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 16),
                          height: 6,
                          width: 50,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Flexible(
                        child: SingleChildScrollView(
                          controller: modalScrollController,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    height: isMobile ? 240 : 350,
                                    width: double.infinity,
                                    padding: EdgeInsets.all(isMobile ? 16 : 32),
                                    margin: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 16 : 24,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAE5F0),
                                      borderRadius: BorderRadius.circular(
                                        isMobile ? 24 : 32,
                                      ),
                                      border: Border.all(
                                        color: Colors.black.withOpacity(0.04),
                                        width: 2,
                                      ),
                                    ),
                                    child: Hero(
                                      tag: 'product-${product.id}',
                                      child: product.imageUrl.isNotEmpty
                                          ? Image.network(
                                              product.imageUrl,
                                              fit: BoxFit.contain,
                                            )
                                          : Icon(
                                              Icons.image,
                                              size: isMobile ? 60 : 80,
                                              color: Colors.grey,
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 16,
                                    right: isMobile ? 32 : 40,
                                    child: InkWell(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          isMobile ? 8 : 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 10,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.black87,
                                          size: isMobile ? 16 : 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isLoggedIn &&
                                      product.couponCode.isNotEmpty)
                                    Positioned(
                                      top: 16,
                                      left: isMobile ? 32 : 40,
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isMobile ? 12 : 16,
                                          vertical: isMobile ? 6 : 8,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              _hotPink,
                                              Colors.orangeAccent,
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _hotPink.withOpacity(0.4),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.local_offer,
                                              color: Colors.white,
                                              size: isMobile ? 12 : 14,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              "SAVE ₱${product.discountAmount.toStringAsFixed(0)}",
                                              style: GoogleFonts.dmSans(
                                                color: Colors.white,
                                                fontSize: isMobile ? 10 : 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                ],
                              ),

                              Padding(
                                padding: EdgeInsets.all(isMobile ? 20.0 : 32.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: GoogleFonts.nunito(
                                        fontSize: isMobile ? 22 : 36,
                                        fontWeight: FontWeight.w900,
                                        color: _darkText,
                                        height: 1.1,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 8,
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFF10B981,
                                            ).withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            "In Stock",
                                            style: GoogleFonts.dmSans(
                                              color: const Color(0xFF10B981),
                                              fontSize: isMobile ? 10 : 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: isMobile ? 16 : 20,
                                            ),
                                            Icon(
                                              Icons.star_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: isMobile ? 16 : 20,
                                            ),
                                            Icon(
                                              Icons.star_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: isMobile ? 16 : 20,
                                            ),
                                            Icon(
                                              Icons.star_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: isMobile ? 16 : 20,
                                            ),
                                            Icon(
                                              Icons.star_half_rounded,
                                              color: const Color(0xFFF59E0B),
                                              size: isMobile ? 16 : 20,
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              "4.8 (124)",
                                              style: GoogleFonts.dmSans(
                                                color: _mutedText,
                                                fontSize: isMobile ? 11 : 13,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 12,
                                      runSpacing: 8,
                                      children: [
                                        Text(
                                          "₱${displayPrice.toStringAsFixed(2)}",
                                          style: GoogleFonts.nunito(
                                            color: _primaryViolet,
                                            fontSize: isMobile ? 28 : 42,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        if (!isRetail)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              "🎉 Wholesale Active",
                                              style: GoogleFonts.dmSans(
                                                color: Colors.amber.shade900,
                                                fontWeight: FontWeight.w800,
                                                fontSize: isMobile ? 10 : 12,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),

                                    Text(
                                      "Description",
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                        fontSize: isMobile ? 16 : 20,
                                        color: _darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      product.description.isNotEmpty
                                          ? product.description
                                          : "No description available for this product.",
                                      style: GoogleFonts.dmSans(
                                        color: _mutedText,
                                        height: 1.5,
                                        fontSize: isMobile ? 13 : 16,
                                      ),
                                    ),

                                    const SizedBox(height: 24),
                                    Text(
                                      "Select Variation",
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w800,
                                        fontSize: isMobile ? 16 : 20,
                                        color: _darkText,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        _buildVariationChip(
                                          "Retail",
                                          isRetail,
                                          _primaryViolet,
                                          isMobile,
                                          () => setModalState(() {
                                            selectedPriceType = 'retail';
                                            quantity = 1;
                                          }),
                                        ),
                                        _buildVariationChip(
                                          "Wholesale (12+)",
                                          !isRetail,
                                          _primaryViolet,
                                          isMobile,
                                          () => setModalState(() {
                                            selectedPriceType = 'wholesale';
                                            quantity = 1;
                                          }),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: isMobile ? 80 : 60),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ADD TO CART BOTTOM BAR
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 16 : 40,
                          vertical: isMobile ? 12 : 24,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, -10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 4 : 8,
                                vertical: isMobile ? 4 : 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAE5F0),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.03),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.remove,
                                      size: isMobile ? 18 : 20,
                                      color: Colors.black87,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        if (quantity > 1) {
                                          quantity--;
                                        } else if (quantity == 1 &&
                                            selectedPriceType == 'wholesale') {
                                          selectedPriceType = 'retail';
                                          quantity = 11;
                                        }
                                      });
                                    },
                                  ),
                                  Container(
                                    constraints: BoxConstraints(
                                      minWidth: isMobile ? 24 : 30,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      "$quantity",
                                      style: GoogleFonts.nunito(
                                        fontWeight: FontWeight.w900,
                                        fontSize: isMobile ? 16 : 20,
                                        color: _darkText,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: Icon(
                                      Icons.add,
                                      size: isMobile ? 18 : 20,
                                      color: _primaryViolet,
                                    ),
                                    onPressed: () {
                                      setModalState(() {
                                        if (selectedPriceType == 'retail' &&
                                            quantity == 11) {
                                          selectedPriceType = 'wholesale';
                                          quantity = 1;
                                        } else {
                                          quantity++;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: isMobile ? 12 : 24),

                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  final cartProvider =
                                      Provider.of<CartProvider>(
                                        context,
                                        listen: false,
                                      );

                                  for (int i = 0; i < quantity; i++) {
                                    cartProvider.addItem(
                                      product,
                                      selectedPriceType,
                                    );
                                  }

                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Added $quantity items to Cart',
                                        style: GoogleFonts.dmSans(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      backgroundColor: _primaryViolet,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  height: isMobile ? 48 : 64,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        _primaryVioletLight,
                                        _primaryViolet,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: _clayButtonShadow,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        color: Colors.white,
                                        size: isMobile ? 16 : 22,
                                      ),
                                      SizedBox(width: isMobile ? 6 : 12),
                                      Flexible(
                                        child: Text(
                                          "Add - ₱${totalPrice.toStringAsFixed(2)}",
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.nunito(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: isMobile ? 14 : 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // FLOATING SCROLL DOWN NOTICE
                  if (showScrollNotice)
                    Positioned(
                      bottom: isMobile ? 100 : 110,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: AnimatedOpacity(
                          opacity: showScrollNotice ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: _hotPink,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: _hotPink.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.arrow_downward,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "Scroll Down",
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildVariationChip(
    String label,
    bool isSelected,
    Color color,
    bool isMobile,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16 : 24,
          vertical: isMobile ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
            width: 2,
          ),
          boxShadow: isSelected ? _clayButtonShadow : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: isMobile ? 14 : 16,
                ),
              ),
            Text(
              label,
              style: GoogleFonts.dmSans(
                color: isSelected ? Colors.white : _darkText,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 13 : 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    final isMobile = screenWidth < 768;

    final filteredProducts = _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery);
      final matchesCategory =
          _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final bool isLoggedIn = snapshot.hasData;

        return Scaffold(
          backgroundColor: _canvas,
          extendBodyBehindAppBar: true,
          appBar: _buildGlassAppBar(cartProvider, screenWidth),
          body: Stack(
            children: [
              Positioned(
                top: -100,
                left: -100,
                child: Container(
                  height: 400,
                  width: 400,
                  decoration: BoxDecoration(
                    color: _primaryVioletLight.withOpacity(0.2),
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
                right: -100,
                child: Container(
                  height: 500,
                  width: 500,
                  decoration: BoxDecoration(
                    color: _hotPink.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                    child: const SizedBox(),
                  ),
                ),
              ),

              _isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: _primaryViolet),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: isMobile ? 80 : 120),

                          PremiumHeroSlideshow(
                            screenWidth: screenWidth,
                            primaryColor: _primaryViolet,
                            secondaryColor: _hotPink,
                          ),

                          const SizedBox(height: 40),
                          _buildPremiumCategories(isMobile),
                          const SizedBox(height: 20),

                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1400),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isMobile ? 12 : 40,
                                ),
                                child: filteredProducts.isEmpty
                                    ? SizedBox(
                                        height: 300,
                                        child: Center(
                                          child: Text(
                                            "No products found",
                                            style: GoogleFonts.nunito(
                                              color: _mutedText,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      )
                                    : GridView.builder(
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            SliverGridDelegateWithFixedCrossAxisCount(
                                              crossAxisCount: screenWidth < 1100
                                                  ? 2
                                                  : 4,
                                              childAspectRatio: isMobile
                                                  ? 0.50
                                                  : (screenWidth < 1100
                                                        ? 0.65
                                                        : 0.70),
                                              crossAxisSpacing: isMobile
                                                  ? 12
                                                  : 32,
                                              mainAxisSpacing: isMobile
                                                  ? 16
                                                  : 48,
                                            ),
                                        itemCount: filteredProducts.length,
                                        itemBuilder: (context, index) {
                                          final product =
                                              filteredProducts[index];
                                          return ClayProductCard(
                                            product: product,
                                            primaryColor: _primaryViolet,
                                            isLoggedIn: isLoggedIn,
                                            isMobile: isMobile,
                                            onTap: () => _showProductDetails(
                                              context,
                                              product,
                                              isLoggedIn,
                                            ),
                                            onAddToCart: () {
                                              cartProvider.addItem(
                                                product,
                                                'retail',
                                              );
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Added to Cart',
                                                    style: GoogleFonts.dmSans(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  backgroundColor:
                                                      _primaryViolet,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                  ),
                                                  behavior:
                                                      SnackBarBehavior.floating,
                                                ),
                                              );
                                            },
                                          );
                                        },
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),

                          _buildProfessionalFooter(isMobile),
                        ],
                      ),
                    ),
            ],
          ),
        );
      },
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(48), // Premium heavily rounded top
        ),
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

  PreferredSizeWidget _buildGlassAppBar(CartProvider cart, double screenWidth) {
    final bool isMobile = screenWidth < 768;
    final bool isTablet = screenWidth >= 768 && screenWidth < 1100;

    final user = FirebaseAuth.instance.currentUser;
    final String photoUrl = user?.photoURL ?? '';

    return PreferredSize(
      preferredSize: Size.fromHeight(isMobile ? 80 : 100),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 40,
              vertical: isMobile ? 8 : 10,
            ),
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.6)),
            child: SafeArea(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: RichText(
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: GoogleFonts.nunito(
                          fontWeight: FontWeight.w900,
                          fontSize: isMobile ? 16 : 28,
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
                  ),
                  if (!isMobile)
                    Container(
                      width: isTablet ? 250 : 400,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F1FA),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.03),
                          width: 1.5,
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.dmSans(fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search products...',
                          hintStyle: GoogleFonts.dmSans(color: _mutedText),
                          prefixIcon: Icon(
                            Icons.search,
                            color: _primaryViolet,
                            size: 24,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                  Row(
                    children: [
                      _buildAppBarIcon(
                        Icons.shopping_cart_rounded,
                        cart.totalQuantity,
                        () => context.go('/cart'),
                        isMobile,
                      ),
                      SizedBox(width: isMobile ? 8 : 16),
                      InkWell(
                        onTap: () => context.go('/orders'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: isMobile ? 40 : 56,
                          height: isMobile ? 40 : 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: _clayCardShadow,
                            image: photoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: photoUrl.isEmpty
                              ? Icon(
                                  Icons.person_rounded,
                                  color: _primaryViolet,
                                  size: isMobile ? 20 : 24,
                                )
                              : null,
                        ),
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

  Widget _buildAppBarIcon(
    IconData icon,
    int badgeCount,
    VoidCallback onTap,
    bool isMobile,
  ) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: isMobile ? 40 : 56,
            height: isMobile ? 40 : 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _clayCardShadow,
            ),
            child: Icon(icon, color: _darkText, size: isMobile ? 20 : 24),
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
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
                  fontSize: isMobile ? 10 : 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPremiumCategories(bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 40,
        vertical: 10,
      ),
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 20 : 32,
                  vertical: isMobile ? 12 : 16,
                ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [_primaryVioletLight, _primaryViolet],
                        )
                      : null,
                  color: isSelected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: isSelected ? _clayButtonShadow : _clayCardShadow,
                ),
                child: Text(
                  cat,
                  style: GoogleFonts.nunito(
                    color: isSelected ? Colors.white : _mutedText,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700,
                    fontSize: isMobile ? 13 : 16,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// --- CLAYMORPHISM PRODUCT CARD ---
class ClayProductCard extends StatefulWidget {
  final Product product;
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onAddToCart;
  final bool isLoggedIn;
  final bool isMobile;

  const ClayProductCard({
    super.key,
    required this.product,
    required this.primaryColor,
    required this.onTap,
    required this.onAddToCart,
    required this.isLoggedIn,
    required this.isMobile,
  });

  @override
  State<ClayProductCard> createState() => _ClayProductCardState();
}

class _ClayProductCardState extends State<ClayProductCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.translationValues(
            0,
            _isPressed ? 4 : (_isHovered ? -12 : 0),
            0,
          )..scale(_isPressed ? 0.96 : 1.0),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(widget.isMobile ? 24 : 32),
            boxShadow: _isPressed
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(5, 5),
                    ),
                  ]
                : (_isHovered
                      ? [
                          BoxShadow(
                            color: const Color(0xFFA096B4).withOpacity(0.4),
                            blurRadius: 40,
                            offset: const Offset(20, 20),
                          ),
                          const BoxShadow(
                            color: Colors.white,
                            blurRadius: 30,
                            offset: Offset(-12, -12),
                          ),
                        ]
                      : [
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
                        ]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 6,
                child: Padding(
                  padding: EdgeInsets.all(widget.isMobile ? 12.0 : 16.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAE5F0),
                      borderRadius: BorderRadius.circular(
                        widget.isMobile ? 16 : 24,
                      ),
                      border: Border.all(
                        color: Colors.black.withOpacity(0.03),
                        width: 1.5,
                      ),
                    ),
                    padding: EdgeInsets.all(widget.isMobile ? 16 : 24),
                    child: Center(
                      child: AnimatedScale(
                        scale: _isHovered ? 1.1 : 1.0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutBack,
                        child: widget.product.imageUrl.isNotEmpty
                            ? Image.network(
                                widget.product.imageUrl,
                                fit: BoxFit.contain,
                              )
                            : Icon(
                                Icons.image,
                                color: Colors.grey,
                                size: widget.isMobile ? 30 : 40,
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    widget.isMobile ? 16 : 24,
                    0,
                    widget.isMobile ? 16 : 24,
                    widget.isMobile ? 16 : 24,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        widget.product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.nunito(
                          fontSize: widget.isMobile ? 15 : 18,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF332F3A),
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.product.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: widget.isMobile ? 11 : 13,
                          color: const Color(0xFF635F69),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              '₱${widget.product.retailPrice.toStringAsFixed(0)}',
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.nunito(
                                fontSize: widget.isMobile ? 16 : 22,
                                fontWeight: FontWeight.w900,
                                color: widget.primaryColor,
                                letterSpacing: -1,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onAddToCart,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.all(
                                widget.isMobile ? 10 : 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isHovered
                                      ? [
                                          const Color(0xFFA78BFA),
                                          const Color(0xFF7C3AED),
                                        ]
                                      : [Colors.white, Colors.white],
                                ),
                                borderRadius: BorderRadius.circular(
                                  widget.isMobile ? 12 : 16,
                                ),
                                boxShadow: _isHovered
                                    ? [
                                        BoxShadow(
                                          color: widget.primaryColor
                                              .withOpacity(0.4),
                                          blurRadius: 16,
                                          offset: const Offset(8, 8),
                                        ),
                                        const BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 10,
                                          offset: Offset(-4, -4),
                                        ),
                                      ]
                                    : [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 10,
                                          offset: const Offset(4, 4),
                                        ),
                                      ],
                              ),
                              child: Icon(
                                Icons.add_shopping_cart_rounded,
                                size: widget.isMobile ? 16 : 20,
                                color: _isHovered
                                    ? Colors.white
                                    : widget.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- CLAYMORPHISM HERO SLIDESHOW WITH 3D ORB ICONS ---
class PremiumHeroSlideshow extends StatefulWidget {
  final double screenWidth;
  final Color primaryColor;
  final Color secondaryColor;
  const PremiumHeroSlideshow({
    super.key,
    required this.screenWidth,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  State<PremiumHeroSlideshow> createState() => _PremiumHeroSlideshowState();
}

class _PremiumHeroSlideshowState extends State<PremiumHeroSlideshow> {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  late List<Map<String, dynamic>> _slides;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _slides = [
      {
        'tag': '100% Authentic Quality',
        'title': 'Fresh Groceries,\nDelivered Fast.',
        'subtitle':
            'Experience the finest selection of daily essentials with VN Brigade.',
        'colors': [widget.primaryColor, const Color(0xFF5A259A)],
        'icon': Icons.shopping_basket_rounded,
        'orbColors': [const Color(0xFFA78BFA), const Color(0xFF5A259A)],
      },
      {
        'tag': 'Huge Discounts',
        'title': 'Lowest Prices\nGuaranteed.',
        'subtitle': 'Save more on your favorite brands every single day.',
        'colors': [widget.secondaryColor, const Color(0xFFFF9D42)],
        'icon': Icons.local_offer_rounded,
        'orbColors': [const Color(0xFFF472B6), const Color(0xFFE11D48)],
      },
      {
        'tag': 'Premium Selection',
        'title': 'Handpicked For\nYour Family.',
        'subtitle': 'Only the best quality products make it to our shelves.',
        'colors': [const Color(0xFF0EA5E9), const Color(0xFF0284C7)],
        'icon': Icons.verified_rounded,
        'orbColors': [const Color(0xFF7DD3FC), const Color(0xFF0369A1)],
      },
    ];

    _startSlideshow();
  }

  void _startSlideshow() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      _currentPage = (_currentPage < _slides.length - 1) ? _currentPage + 1 : 0;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 1000),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _build3DOrbIcon(
    IconData icon,
    List<Color> gradientColors,
    double size,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: size * 0.2,
            offset: Offset(size * 0.1, size * 0.1),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.4),
            blurRadius: size * 0.15,
            offset: Offset(-size * 0.05, -size * 0.05),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: size * 0.1,
            left: size * 0.15,
            child: Container(
              width: size * 0.4,
              height: size * 0.2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(size),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.4),
                    blurRadius: size * 0.1,
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Icon(
              icon,
              size: size * 0.45,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = widget.screenWidth < 768;
    final bool isTablet =
        widget.screenWidth >= 768 && widget.screenWidth < 1100;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 40),
          height: isMobile ? 240 : (isTablet ? 320 : 420),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (int page) =>
                    setState(() => _currentPage = page),
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Container(
                    padding: EdgeInsets.all(
                      isMobile ? 24 : (isTablet ? 40 : 60),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(isMobile ? 32 : 48),
                      gradient: LinearGradient(
                        colors: slide['colors'],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: slide['colors'][0].withOpacity(0.4),
                          blurRadius: 40,
                          offset: const Offset(20, 20),
                        ),
                        const BoxShadow(
                          color: Colors.white,
                          blurRadius: 30,
                          offset: Offset(-10, -10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  slide['tag'],
                                  style: GoogleFonts.nunito(
                                    color: Colors.white,
                                    fontSize: isMobile
                                        ? 10
                                        : (isTablet ? 12 : 14),
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                slide['title'],
                                style: GoogleFonts.nunito(
                                  color: Colors.white,
                                  fontSize: isMobile
                                      ? 28
                                      : (isTablet ? 38 : 64),
                                  fontWeight: FontWeight.w900,
                                  height: 1.1,
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                slide['subtitle'],
                                style: GoogleFonts.dmSans(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: isMobile
                                      ? 12
                                      : (isTablet ? 14 : 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isMobile)
                          Expanded(
                            child: Center(
                              child: _build3DOrbIcon(
                                slide['icon'],
                                slide['orbColors'],
                                isTablet ? 140 : 220,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Positioned(
                bottom: isMobile ? 16 : 32,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 8,
                      width: _currentPage == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
