import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  String _sortBy = 'name';
  bool _ascending = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _selectedCategory = 'All';
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
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
        sortBy: _sortBy,
        ascending: _ascending,
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
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  IconData _getCategoryIcon(String category) {
    category = category.toLowerCase();
    if (category.contains('cigar')) return Icons.smoking_rooms;
    if (category.contains('clean')) return Icons.cleaning_services;
    if (category.contains('coffee') || category.contains('milk')) return Icons.coffee;
    if (category.contains('food') || category.contains('snack')) return Icons.cookie;
    if (category.contains('liquor')) return Icons.liquor;
    if (category.contains('rice')) return Icons.rice_bowl;
    if (category.contains('drink')) return Icons.local_drink;
    if (category.contains('choc')) return Icons.cake;
    if (category == 'all') return Icons.grid_view;
    return Icons.category;
  }

  void _showProductDetails(BuildContext context, Product product, bool isLoggedIn) {
    String selectedPriceType = 'retail';
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final bool isRetail = selectedPriceType == 'retail';
          final Color activeColor = const Color(0xFFEE4D2D);

          return Container(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)), // ADDED: Smoother top radius
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 20, spreadRadius: 5) // ADDED: Premium shadow behind sheet
              ]
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ADDED: Modern Drag Handle Pill
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Container(
                              height: 300,
                              width: double.infinity,
                              color: Colors.white,
                              padding: const EdgeInsets.all(24), // ADDED: More breathing room for the image
                              child: product.imageUrl.isNotEmpty
                                  ? Container(
                                      // ADDED: Shadow and rounded corners to the image itself
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(16),
                                        // FIXED: Removed the backgroundColor parameter to satisfy newer Flutter rules
                                        child: Image.network(
                                          product.imageUrl, 
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.image, size: 50, color: Colors.grey),
                            ),
                            Positioned(
                              top: 10, right: 10,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.black87, size: 26),
                                onPressed: () => Navigator.pop(context),
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.9),
                                  elevation: 2, // ADDED: Shadow to close button
                                ),
                              ),
                            )
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20.0), // ADDED: Increased padding for modern feel
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ADDED: Small label above price
                              const Text("Current Price", style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
                              Text(
                                "₱${isRetail ? product.retailPrice.toStringAsFixed(2) : product.wholesalePrice.toStringAsFixed(2)}", 
                                style: TextStyle(color: activeColor, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5) // ADDED: Bolder, tighter text
                              ),
                              const SizedBox(height: 8),
                              Text(product.name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
                              
                              const SizedBox(height: 20),
                              const Divider(height: 1), // ADDED: Clean separator line
                              const SizedBox(height: 20),
                              
                              const Text("Product Description", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                              const SizedBox(height: 8),
                              Text(
                                product.description.isNotEmpty ? product.description : "No description available.",
                                style: TextStyle(color: Colors.grey[700], height: 1.6, fontSize: 14), // ADDED: Better line height for readability
                              ),
                              
                              const SizedBox(height: 24),
                              
                              const Text("Variation", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12, // ADDED: Slightly more spacing
                                children: [
                                  _buildVariationChip("Retail Price", isRetail, activeColor, () => setState(() => selectedPriceType = 'retail')),
                                  _buildVariationChip("Wholesale", !isRetail, activeColor, () => setState(() => selectedPriceType = 'wholesale')),
                                ],
                              ),
                              
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.all(16), // ADDED: More padding
                                decoration: BoxDecoration(
                                  // ADDED: Premium Gradient background instead of flat blue
                                  gradient: LinearGradient(
                                    colors: [Colors.blue.shade50, Colors.blue.shade100.withOpacity(0.5)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.shade200, width: 0.5), // ADDED: Subtle border
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.verified_user, color: Colors.blue[700], size: 24), // ADDED: Larger icon
                                    const SizedBox(width: 12),
                                    Text("Lowest Price Guaranteed", style: TextStyle(color: Colors.blue[800], fontSize: 14, fontWeight: FontWeight.bold))
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), // ADDED: Better padding
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(top: BorderSide(color: Colors.grey.shade200)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)) // ADDED: Shadow pointing up
                    ]
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            final cartProvider = Provider.of<CartProvider>(context, listen: false);
                            cartProvider.addItem(product, selectedPriceType);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to Cart')));
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: activeColor, width: 1.5), // ADDED: Thicker border
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // ADDED: More rounded
                            backgroundColor: activeColor.withOpacity(0.05), // ADDED: Very subtle orange tint
                          ),
                          child: Icon(Icons.add_shopping_cart, color: activeColor),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: () {
                            final cartProvider = Provider.of<CartProvider>(context, listen: false);
                            cartProvider.addItem(product, selectedPriceType);
                            Navigator.pop(context);
                            context.go('/cart');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: activeColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 2, // ADDED: Elevation for the button
                            shadowColor: activeColor.withOpacity(0.5), // ADDED: Colored shadow
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text("Buy Now", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildVariationChip(String label, bool isSelected, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8), // ADDED: Ripple effect respects borders
      child: AnimatedContainer( // ADDED: AnimatedContainer for smooth color transitions
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), // ADDED: Wider chips
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white, // ADDED: Tinted background when selected
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 1.5 : 1), // ADDED: Thicker border on select
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!isSelected) BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)) // ADDED: Subtle shadow on unselected
          ]
        ),
        child: Text(label, style: TextStyle(color: isSelected ? color : Colors.black87, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);

    final filteredProducts = _products.where((product) {
      final matchesSearch = product.name.toLowerCase().contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'All' || product.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        final User? user = snapshot.data;
        final bool isLoggedIn = user != null;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: const Color(0xFFEE4D2D),
            elevation: 0,
            toolbarHeight: 70,
            // 🔥 UPDATED: REMOVED LOGO, JUST TEXT 🔥
            title: const Padding(
              padding: EdgeInsets.only(left: 16.0),
              child: Text(
                "VN Brigade Groceries PH",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)) // ADDED: Subtle text shadow
                  ]
                ),
              ),
            ),
            actions: [
              // 🔥 FIXED: ORDER TRACKER ICON (Filled version for visibility) 🔥
              if (isLoggedIn)
                IconButton(
                  icon: const Icon(Icons.local_shipping, color: Colors.white, size: 28), // Changed to solid icon
                  tooltip: 'My Orders',
                  onPressed: () => context.go('/orders'),
                ),

              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28),
                    onPressed: () => context.go('/cart'),
                  ),
                  if (cartProvider.totalQuantity > 0)
                    Positioned(
                      top: 8, right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFFEE4D2D))),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          '${cartProvider.totalQuantity}',
                          style: const TextStyle(color: Color(0xFFEE4D2D), fontSize: 10, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              if (!isLoggedIn)
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text("Login", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                )
              else 
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              const SizedBox(width: 10),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                alignment: Alignment.center,
                child: Container(
                  height: 48, // ADDED: Slightly taller for better touch target
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8), // ADDED: More rounded corners
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)) // ADDED: Shadow to search bar
                    ]
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search for sardines, rice, coffee...',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14), // ADDED: Calmer hint text color
                      prefixIcon: Icon(Icons.search, color: Color(0xFFEE4D2D), size: 24),
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 14), // ADDED: Centered text better
                    ),
                  ),
                ),
              ),
            ),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFEE4D2D))) // ADDED: Brand colored loader
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        height: 120,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFEE4D2D), Color(0xFFFF7337)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 800),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildBannerItem(Icons.verified, "VNB Mall", "100% Authentic"),
                                _buildBannerItem(Icons.flash_on, "Fast Delivery", "Order Now"), 
                                _buildBannerItem(Icons.confirmation_number, "Vouchers", "Claim Now"),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      Container(
                        color: Colors.transparent, // ADDED: Let the scaffold background show through
                        padding: const EdgeInsets.symmetric(vertical: 10), // ADDED: Tighter vertical padding
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 1600),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _categories.map((category) {
                                  final isSelected = _selectedCategory == category;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8), // ADDED: Tighter horizontal spacing
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedCategory = category),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Column(
                                        children: [
                                          AnimatedContainer( // ADDED: Animated transition for category selection
                                            duration: const Duration(milliseconds: 200),
                                            padding: const EdgeInsets.all(14), // ADDED: Larger click area
                                            decoration: BoxDecoration(
                                              color: isSelected ? const Color(0xFFEE4D2D) : Colors.white, // ADDED: Fill orange when selected
                                              border: Border.all(color: isSelected ? const Color(0xFFEE4D2D) : Colors.grey.shade200),
                                              borderRadius: BorderRadius.circular(16), // ADDED: More rounded
                                              boxShadow: [
                                                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2)) // ADDED: Category shadow
                                              ]
                                            ),
                                            child: Icon(
                                              _getCategoryIcon(category), 
                                              color: isSelected ? Colors.white : Colors.grey.shade600, // ADDED: Icon turns white when selected
                                              size: 26
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isSelected ? const Color(0xFFEE4D2D) : Colors.black87,
                                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500 // ADDED: Better unselected weight
                                            ),
                                          )
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1600),
                          child: filteredProducts.isEmpty
                              ? const SizedBox(height: 200, child: Center(child: Text("No products found", style: TextStyle(color: Colors.grey, fontSize: 16))))
                              : LayoutBuilder(
                                  builder: (context, constraints) {
                                    int crossAxisCount = 2;
                                    if (constraints.maxWidth > 1200) crossAxisCount = 6;
                                    else if (constraints.maxWidth > 900) crossAxisCount = 5;
                                    else if (constraints.maxWidth > 600) crossAxisCount = 4; // ADDED: Better tablet scaling
                                    
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), // ADDED: Better grid padding
                                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: crossAxisCount,
                                        childAspectRatio: 0.72, // ADDED: Slightly taller cards to fit content better
                                        crossAxisSpacing: 12, // ADDED: More breathing room between cards
                                        mainAxisSpacing: 12,
                                      ),
                                      itemCount: filteredProducts.length,
                                      itemBuilder: (context, index) {
                                        final product = filteredProducts[index];
                                        return ShopeeProductCard(
                                          product: product, 
                                          isLoggedIn: isLoggedIn, 
                                          onTap: () => _showProductDetails(context, product, isLoggedIn)
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ),
                      const SizedBox(height: 60), // ADDED: More bottom padding
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildBannerItem(IconData icon, String title, String sub) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12), // ADDED: Larger banner icons
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2), 
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, spreadRadius: 1) // ADDED: Glow effect to banners
            ]
          ),
          child: Icon(icon, color: Colors.white, size: 28),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.2)),
        Text(sub, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w300)), // ADDED: Cleaner sub text
      ],
    );
  }
}

class ShopeeProductCard extends StatefulWidget {
  final Product product;
  final bool isLoggedIn;
  final VoidCallback onTap;

  const ShopeeProductCard({super.key, required this.product, required this.isLoggedIn, required this.onTap});

  @override
  State<ShopeeProductCard> createState() => _ShopeeProductCardState();
}

class _ShopeeProductCardState extends State<ShopeeProductCard> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      onHover: (hovering) => setState(() => _isHovering = hovering),
      borderRadius: BorderRadius.circular(12), // ADDED: Click ripple respects borders
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _isHovering ? const Color(0xFFEE4D2D).withOpacity(0.5) : Colors.grey.shade200, width: 1), // ADDED: Always show subtle border
          borderRadius: BorderRadius.circular(12), // ADDED: Modern 12px border radius
          boxShadow: [
            if (_isHovering) 
              BoxShadow(color: const Color(0xFFEE4D2D).withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4)) // ADDED: Premium colored hover shadow
            else
              BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 2)) // ADDED: Default soft shadow
          ]
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5, // ADDED: Ratio control
              child: Stack(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: ClipRRect( // ADDED: ClipRRect to prevent image clipping through rounded corners
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                      child: widget.product.imageUrl.isNotEmpty
                          ? Image.network(widget.product.imageUrl, fit: BoxFit.cover)
                          : Container(color: Colors.grey[50], child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 40))),
                    ),
                  ),
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient( // ADDED: Gradient to the best value banner
                          colors: [Colors.orange.shade800, Colors.orange.shade600],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4), // ADDED: Slightly taller banner
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.thumb_up, size: 12, color: Colors.white), // ADDED: Slightly larger icon
                          SizedBox(width: 4),
                          Text("Best Value", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ),
                  if (widget.isLoggedIn && widget.product.couponCode.isNotEmpty)
                    Positioned(
                      top: 8, right: 8, // ADDED: Margin from the edge
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.yellow.shade700,
                          borderRadius: BorderRadius.circular(4), // ADDED: Rounded voucher tag
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2)]
                        ),
                        child: const Text("SALE", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black87)),
                      ),
                    )
                ],
              ),
            ),
            Expanded(
              flex: 3, // ADDED: Ratio control for text area
              child: Padding(
                padding: const EdgeInsets.all(10.0), // ADDED: Better padding
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, // ADDED: Pushes price to the bottom
                  children: [
                    Text(
                      widget.product.name, 
                      maxLines: 2, 
                      overflow: TextOverflow.ellipsis, 
                      style: const TextStyle(fontSize: 13, color: Colors.black87, fontWeight: FontWeight.w500, height: 1.2) // ADDED: Better text styling
                    ),
                    Column( // ADDED: Wrapped bottom elements to keep them together
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.product.couponCode.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFEE4D2D).withOpacity(0.5)),
                              color: const Color(0xFFEE4D2D).withOpacity(0.05), // ADDED: Very soft red background
                              borderRadius: BorderRadius.circular(2)
                            ),
                            child: const Text("Voucher", style: TextStyle(fontSize: 9, color: Color(0xFFEE4D2D), fontWeight: FontWeight.bold)),
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₱${widget.product.retailPrice.toStringAsFixed(0)}', 
                              style: const TextStyle(color: Color(0xFFEE4D2D), fontSize: 18, fontWeight: FontWeight.w900) // ADDED: Bolder price
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Icon(Icons.star, size: 12, color: Colors.amber),
                                  Text(" 5.0", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)), // ADDED: Softer text color
                                ],
                              ),
                            )
                          ],
                        ),
                        const SizedBox(height: 2),
                        const Text("In Stock", style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.w500)), // ADDED: Made stock indicator green
                      ],
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}