import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:fl_chart/fl_chart.dart'; 
import 'package:intl/intl.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/firebase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with TickerProviderStateMixin {
  final FirebaseService _firebaseService = FirebaseService();
  List<Order> _orders = [];
  List<Product> _products = [];
  bool _isLoadingOrders = true;
  bool _isLoadingProducts = true;
  late TabController _tabController;
  bool _isAuthenticated = false;
  final TextEditingController _passwordController = TextEditingController();
  
  // --- SEARCH CONTROLLERS ---
  final TextEditingController _orderSearchController = TextEditingController();
  final TextEditingController _productSearchController = TextEditingController(); 
  String _orderSearchQuery = '';
  String _productSearchQuery = ''; 

  // 🔥 UPDATED CATEGORIES LIST WITH CHOCOLATES 🔥
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
    'Chocolates', // 👈 ADDED HERE
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    _orderSearchController.addListener(() {
      setState(() {
        _orderSearchQuery = _orderSearchController.text.toLowerCase();
      });
    });

    _productSearchController.addListener(() {
      setState(() {
        _productSearchQuery = _productSearchController.text.toLowerCase();
      });
    });
  }

  void _authenticate(String password) {
    if (password == 'admin123') {
      setState(() => _isAuthenticated = true);
      _loadOrders();
      _loadProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid password')));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderSearchController.dispose();
    _productSearchController.dispose();
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order status updated to $status')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating status: $e')));
    }
  }

  // --- ANALYTICS CALCULATIONS ---
  double get _totalRevenue {
    return _orders
        .where((o) => o.status != 'cancelled')
        .fold(0.0, (sum, order) => sum + order.total);
  }

  Map<String, double> get _salesByCategory {
    Map<String, double> categorySales = {};
    Map<String, String> productCategories = {
      for (var p in _products) p.id: p.category
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

  // --- IMAGE UPLOADER ---
  Future<void> _pickAndUploadImage(TextEditingController controller) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'gif'], 
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}_${file.name}';
        final ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
        
        if (file.bytes != null) {
          String extension = file.extension ?? 'jpeg';
          final metadata = SettableMetadata(contentType: 'image/$extension');
          await ref.putData(file.bytes!, metadata);
        }
        
        final downloadUrl = await ref.getDownloadURL();
        controller.text = downloadUrl;
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully!')));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    }
  }

  // --- UI WIDGETS ---

  void _showOrderDetailsDialog(Order order) {
    String userType = order.userId == 'guest' ? 'Guest User' : 'Registered Member';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Order: ${order.referenceId}', style: const TextStyle(fontSize: 18))),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey[300]!)),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: order.userId == 'guest' ? Colors.grey[300] : Colors.blue[100],
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          userType.toUpperCase(), 
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10, 
                            fontWeight: FontWeight.bold,
                            color: order.userId == 'guest' ? Colors.grey[800] : Colors.blue[900]
                          ),
                        ),
                      ),
                      
                      _buildDetailRow(Icons.person, 'Customer', order.customerName),
                      _buildDetailRow(Icons.phone, 'Phone', order.customerPhone),
                      _buildDetailRow(Icons.location_on, 'Address', order.customerAddress),
                      const Divider(),
                      _buildDetailRow(Icons.calendar_today, 'Date', order.createdAt.toString().split('.')[0]),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text('Items Ordered:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columnSpacing: 20,
                    headingRowColor: MaterialStateProperty.all(Colors.green[50]),
                    columns: const [
                      DataColumn(label: Text('Product', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                      DataColumn(label: Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold))),
                    ],
                    rows: order.items.map((item) {
                      final subtotal = item.price * item.quantity;
                      return DataRow(cells: [
                        DataCell(Text('${item.productName} (${item.priceType}) x${item.quantity}')),
                        DataCell(Text('₱${item.price.toStringAsFixed(2)}')),
                        DataCell(Text('₱${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]);
                    }).toList(),
                  ),
                ),
                const Divider(thickness: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('₱${order.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                
                const Text('Update Status (Tracker):', style: TextStyle(fontWeight: FontWeight.w500)),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 5),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: order.status,
                      isExpanded: true,
                      items: ['pending', 'confirmed', 'shipped', 'delivered', 'cancelled']
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status.toUpperCase(), style: TextStyle(color: status == 'pending' ? Colors.orange : status == 'delivered' ? Colors.green : Colors.black)),
                              ))
                          .toList(),
                      onChanged: (newStatus) {
                        if (newStatus != null) _updateStatus(order.id, newStatus);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Order'),
                  content: const Text('Are you sure? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                    ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.white))),
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
            child: const Text('Delete Order', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w500)),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }

  void _showProductDialog([Product? product]) {
    final nameController = TextEditingController(text: product?.name);
    final marketPriceController = TextEditingController(text: product?.retailPrice.toString());
    final vnbPriceController = TextEditingController(text: product?.wholesalePrice.toString());
    final descriptionController = TextEditingController(text: product?.description);
    final imageUrlController = TextEditingController(text: product?.imageUrl);
    
    // Coupon Controllers
    final couponCodeController = TextEditingController(text: product?.couponCode);
    final discountAmountController = TextEditingController(text: product?.discountAmount.toString() ?? '0.0');
    
    String selectedCategory = product?.category ?? _categories.first;
    if (selectedCategory.isEmpty || !_categories.contains(selectedCategory)) {
      selectedCategory = _categories.first;
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(product == null ? 'Add Product' : 'Edit Product'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                  TextField(controller: marketPriceController, decoration: const InputDecoration(labelText: 'Retail Price'), keyboardType: TextInputType.number),
                  TextField(controller: vnbPriceController, decoration: const InputDecoration(labelText: 'Wholesale Price'), keyboardType: TextInputType.number),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                  TextField(
                    controller: imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      suffixIcon: IconButton(icon: const Icon(Icons.file_upload), onPressed: () => _pickAndUploadImage(imageUrlController)),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    ),
                    items: _categories.map((String category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setDialogState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  const Align(alignment: Alignment.centerLeft, child: Text("Promo Settings (Optional)", style: TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      children: [
                        TextField(
                          controller: couponCodeController,
                          decoration: const InputDecoration(labelText: 'Coupon Code (e.g. SALE10)', prefixIcon: Icon(Icons.local_offer)),
                        ),
                        TextField(
                          controller: discountAmountController,
                          decoration: const InputDecoration(labelText: 'Discount Amount (₱)', prefixIcon: Icon(Icons.money_off)),
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final name = nameController.text.trim();
                    final marketPrice = double.tryParse(marketPriceController.text.trim());
                    final vnbPrice = double.tryParse(vnbPriceController.text.trim());
                    
                    final couponCode = couponCodeController.text.trim();
                    final discountAmount = double.tryParse(discountAmountController.text.trim()) ?? 0.0;

                    if (name.isEmpty || marketPrice == null || vnbPrice == null) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
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
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(product == null ? 'Product added!' : 'Product updated!')));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- ANALYTICS UI ---
  Widget _buildAnalyticsTab() {
    final weeklySales = _weeklySales;
    final categorySales = _salesByCategory;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Card(
                  color: const Color(0xFFFF6B35),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Revenue', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('₱${_totalRevenue.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Card(
                  color: Colors.blueAccent,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Total Orders', style: TextStyle(color: Colors.white70, fontSize: 14)),
                        const SizedBox(height: 5),
                        Text('${_orders.length}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 30),
          
          const Text('Last 7 Days Sales', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            height: 200,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final dayIndex = 6 - value.toInt(); 
                        final date = DateTime.now().subtract(Duration(days: dayIndex));
                        return Text(DateFormat('E').format(date)[0], style: const TextStyle(fontSize: 10, color: Colors.grey));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                barGroups: weeklySales.asMap().entries.map((e) {
                  return BarChartGroupData(
                    x: e.key,
                    barRods: [BarChartRodData(toY: e.value, color: const Color(0xFFFF6B35), width: 15, borderRadius: BorderRadius.circular(4))],
                  );
                }).toList(),
              ),
            ),
          ),
          
          const SizedBox(height: 30),

          const Text('Sales by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          Container(
            height: 250,
             padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10)]),
            child: categorySales.isEmpty 
              ? const Center(child: Text("No Sales Data Yet"))
              : Row(
                children: [
                  Expanded(
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: categorySales.entries.map((e) {
                          final isLarge = e.value > 500; 
                          return PieChartSectionData(
                            color: Colors.primaries[categorySales.keys.toList().indexOf(e.key) % Colors.primaries.length],
                            value: e.value,
                            title: '',
                            radius: isLarge ? 60 : 50,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: categorySales.entries.map((e) {
                      final color = Colors.primaries[categorySales.keys.toList().indexOf(e.key) % Colors.primaries.length];
                      return Row(
                        children: [
                          Container(width: 10, height: 10, color: color),
                          const SizedBox(width: 5),
                          Text('${e.key} (₱${e.value.toStringAsFixed(0)})', style: const TextStyle(fontSize: 12)),
                        ],
                      );
                    }).toList(),
                  )
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
        appBar: AppBar(title: const Text('Admin Login')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Enter Admin Password'),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  onSubmitted: _authenticate,
                ),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => _authenticate(_passwordController.text), child: const Text('Login')),
              ],
            ),
          ),
        ),
      );
    }

    // Filter Logic for Products
    final filteredProducts = _products.where((product) {
      return product.name.toLowerCase().contains(_productSearchQuery);
    }).toList();

    // Filter Logic for Orders
    final filteredOrders = _orders.where((order) {
      return order.referenceId.toLowerCase().contains(_orderSearchQuery);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Analytics'),
            Tab(text: 'Orders'),
            Tab(text: 'Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoadingOrders || _isLoadingProducts 
            ? const Center(child: CircularProgressIndicator()) 
            : _buildAnalyticsTab(),
            
          _isLoadingOrders
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: _orderSearchController,
                        decoration: const InputDecoration(labelText: 'Search by Reference ID', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            child: InkWell(
                              onTap: () => _showOrderDetailsDialog(order),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    Icon(
                                      order.status == 'delivered' ? Icons.check_circle : order.status == 'cancelled' ? Icons.cancel : Icons.pending,
                                      color: order.status == 'delivered' ? Colors.green : order.status == 'cancelled' ? Colors.red : Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(order.referenceId, style: const TextStyle(fontWeight: FontWeight.bold)),
                                          Text(order.customerName, style: TextStyle(color: Colors.grey[600])),
                                          Text('₱${order.total.toStringAsFixed(2)} - ${order.status.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green[800])),
                                        ],
                                      ),
                                    ),
                                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
          _isLoadingProducts
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // --- PRODUCT SEARCH BAR ---
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _productSearchController,
                              decoration: const InputDecoration(labelText: 'Search Products', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: () => _showProductDialog(), 
                            icon: const Icon(Icons.add), 
                            label: const Text('Add'),
                            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = filteredProducts[index];
                          return ListTile(
                            leading: product.imageUrl.isNotEmpty
                                ? Image.network(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover, errorBuilder: (c,e,s) => const Icon(Icons.image))
                                : const Icon(Icons.image),
                            title: Text(product.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${product.category} - ₱${product.retailPrice}'),
                                if (product.couponCode.isNotEmpty)
                                  Text("Promo: ${product.couponCode} (-₱${product.discountAmount})", style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showProductDialog(product)),
                                IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () async {
                                  try {
                                    await _firebaseService.deleteProduct(product.id);
                                    _loadProducts();
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                  }
                                }),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }
}