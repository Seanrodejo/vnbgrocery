import 'dart:ui';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/order.dart' as model;

enum AccountTab { dashboard, orderHistory, settings, orderDetails }

class ClientOrdersScreen extends StatefulWidget {
  const ClientOrdersScreen({super.key});

  @override
  State<ClientOrdersScreen> createState() => _ClientOrdersScreenState();
}

class _ClientOrdersScreenState extends State<ClientOrdersScreen> {
  AccountTab _currentTab = AccountTab.dashboard;
  model.Order? _selectedOrder;

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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  String _profileImageUrl = '';
  bool _isSavingProfile = false;
  bool _isSavingAddress = false;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (FirebaseAuth.instance.currentUser == null) {
        context.go('/login');
      }
    });
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailController.text = user.email ?? '';
      _nameController.text = user.displayName ?? 'Customer';
      _profileImageUrl = user.photoURL ?? '';

      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists && doc.data() != null) {
          final data = doc.data()!;
          if (data.containsKey('phone')) {
            _phoneController.text = data['phone'] ?? '';
          }
          if (data.containsKey('address')) {
            _addressController.text = data['address'] ?? '';
          }
          if (data.containsKey('name') &&
              (_nameController.text.isEmpty ||
                  _nameController.text == 'Customer')) {
            _nameController.text = data['name'];
          }
          if (data.containsKey('photoUrl') &&
              data['photoUrl'].toString().isNotEmpty) {
            _profileImageUrl = data['photoUrl'];
          }
        }
      } catch (e) {
        debugPrint("Error loading user data: $e");
      }
      if (mounted) setState(() {});
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickProfileImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Error: Cannot read image file.',
                style: GoogleFonts.dmSans(),
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        setState(() => _isUploadingImage = true);

        const String imgbbApiKey = '23fb97c65be306aef13ed626b935c801';
        final String base64Image = base64Encode(file.bytes!);
        final response = await http.post(
          Uri.parse('https://api.imgbb.com/1/upload'),
          body: {'key': imgbbApiKey, 'image': base64Image},
        );

        if (response.statusCode == 200) {
          final jsonResponse = jsonDecode(response.body);
          final String imageUrl = jsonResponse['data']['url'];

          await user.updatePhotoURL(imageUrl);
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({'photoUrl': imageUrl}, SetOptions(merge: true));

          if (mounted) {
            setState(() {
              _profileImageUrl = imageUrl;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Profile image updated!',
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
        } else {
          throw Exception('ImgBB API Error: ${response.body}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e', style: GoogleFonts.dmSans()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_nameController.text.trim());
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'name': _nameController.text.trim(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Profile saved successfully!',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving profile: $e',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingProfile = false);
    }
  }

  Future<void> _saveAddress() async {
    setState(() => _isSavingAddress = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'address': _addressController.text.trim(),
          'phone': _phoneController.text.trim(),
          'name': _nameController.text.trim(),
        }, SetOptions(merge: true));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Delivery address saved!',
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error saving address: $e',
              style: GoogleFonts.dmSans(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSavingAddress = false);
    }
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(40),
              boxShadow: _clayCardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _hotPink.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.logout_rounded, color: _hotPink, size: 40),
                ),
                const SizedBox(height: 24),
                Text(
                  "Are you sure you want to Log Out?",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: _darkText,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          height: 56,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            "Cancel",
                            style: GoogleFonts.nunito(
                              color: _darkText,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ClaySquishButton(
                        label: "Log Out",
                        primaryColor: _hotPink,
                        onPressed: () {
                          FirebaseAuth.instance.signOut();
                          Navigator.pop(context);
                          context.go('/login');
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 900;
    final isMobile = screenWidth < 768;

    if (user == null) return Scaffold(backgroundColor: _canvas);

    return Scaffold(
      backgroundColor: _canvas,
      extendBodyBehindAppBar: true,
      appBar: _buildGlassAppBar(isMobile),
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
                color: _primaryVioletLight.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              height: 500,
              width: 500,
              decoration: BoxDecoration(
                color: const Color(0xFF0EA5E9).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                child: const SizedBox(),
              ),
            ),
          ),

          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: isMobile ? 100 : 120),

                // FLOATING HERO BANNER
                Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 40,
                    vertical: 24,
                  ),
                  padding: EdgeInsets.symmetric(
                    vertical: isMobile ? 32 : 48,
                    horizontal: isMobile ? 32 : 48,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(48),
                    gradient: LinearGradient(
                      colors: [_primaryVioletLight, _primaryViolet],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryViolet.withOpacity(0.4),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Icon(
                          Icons.dashboard_customize_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Welcome back,",
                              style: GoogleFonts.dmSans(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              _nameController.text.isNotEmpty
                                  ? _nameController.text
                                  : "Customer",
                              style: GoogleFonts.nunito(
                                color: Colors.white,
                                fontSize: isMobile ? 28 : 40,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1,
                                height: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16.0 : 40.0,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1400),
                      child: isDesktop
                          ? Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(flex: 3, child: _buildSidebar()),
                                const SizedBox(width: 40),
                                Expanded(
                                  flex: 9,
                                  child: _buildActiveTabContent(user),
                                ),
                              ],
                            )
                          : Column(
                              children: [
                                _buildSidebar(),
                                const SizedBox(height: 32),
                                _buildActiveTabContent(user),
                              ],
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 80),

                // --- NEW PROFESSIONAL CLAYMORPHISM FOOTER ---
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

  PreferredSizeWidget _buildGlassAppBar(bool isMobile) {
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
                      InkWell(
                        onTap: () => context.go('/'),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: _clayCardShadow,
                          ),
                          child: Icon(
                            Icons.storefront_outlined,
                            color: _darkText,
                            size: 24,
                          ),
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

  Widget _buildSidebar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        boxShadow: _clayCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                "NAVIGATION",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: _mutedText,
                  letterSpacing: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildNavItem(
              Icons.grid_view_rounded,
              "Dashboard",
              AccountTab.dashboard,
            ),
            _buildNavItem(
              Icons.receipt_long_rounded,
              "Order History",
              AccountTab.orderHistory,
            ),
            _buildNavItem(
              Icons.settings_outlined,
              "Settings",
              AccountTab.settings,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Divider(color: Colors.grey.shade200, thickness: 2),
            ),
            _buildNavItem(
              Icons.logout_rounded,
              "Log out",
              null,
              isLogout: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    AccountTab? tab, {
    bool isLogout = false,
  }) {
    final isActive = _currentTab == tab && !isLogout;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: InkWell(
        onTap: () {
          if (isLogout) {
            _showLogoutDialog();
          } else if (tab != null) {
            setState(() {
              _currentTab = tab;
              _selectedOrder = null;
            });
          }
        },
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
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
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? Colors.white
                    : (isLogout ? _hotPink : _mutedText),
              ),
              const SizedBox(width: 16),
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive
                      ? Colors.white
                      : (isLogout ? _hotPink : _darkText),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(User user) {
    switch (_currentTab) {
      case AccountTab.dashboard:
        return _buildDashboard(user);
      case AccountTab.orderHistory:
        return _buildOrderHistory(user);
      case AccountTab.settings:
        return _buildSettings();
      case AccountTab.orderDetails:
        return _selectedOrder != null
            ? _buildOrderDetails(_selectedOrder!)
            : _buildOrderHistory(user);
    }
  }

  Widget _buildModernTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isReadOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isReadOnly ? const Color(0xFFF4F1FA) : const Color(0xFFEAE5F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 2),
      ),
      child: TextField(
        controller: controller,
        readOnly: isReadOnly,
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

  Widget _buildSettings() {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(48),
        boxShadow: _clayCardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Account Settings",
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _darkText,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 48),
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: _clayCardShadow,
                          image: _profileImageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(_profileImageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: _profileImageUrl.isEmpty
                            ? Icon(
                                Icons.person_rounded,
                                size: 64,
                                color: Colors.grey.shade300,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _isUploadingImage ? null : _pickProfileImage,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_primaryVioletLight, _primaryViolet],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: _primaryViolet.withOpacity(0.4),
                                  blurRadius: 16,
                                  offset: const Offset(4, 4),
                                ),
                              ],
                            ),
                            child: _isUploadingImage
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 56),
                _buildModernTextField(
                  _nameController,
                  "Full Name",
                  Icons.person_outline,
                ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  _emailController,
                  "Email Address",
                  Icons.email_outlined,
                  isReadOnly: true,
                ),
                const SizedBox(height: 32),
                ClaySquishButton(
                  label: "Save Profile",
                  primaryColor: _primaryViolet,
                  isLoading: _isSavingProfile,
                  onPressed: _saveProfile,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 56),
                  child: Divider(color: Colors.grey.shade200, thickness: 2),
                ),
                Text(
                  "Delivery Address",
                  style: GoogleFonts.nunito(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                    color: _darkText,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 32),
                isMobile
                    ? Column(
                        children: [
                          _buildModernTextField(
                            _nameController,
                            "Recipient Name",
                            Icons.person_outline,
                          ),
                          const SizedBox(height: 20),
                          _buildModernTextField(
                            _phoneController,
                            "Phone Number",
                            Icons.phone_outlined,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _buildModernTextField(
                              _nameController,
                              "Recipient Name",
                              Icons.person_outline,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: _buildModernTextField(
                              _phoneController,
                              "Phone Number",
                              Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                const SizedBox(height: 20),
                _buildModernTextField(
                  _addressController,
                  "Complete Address (Street, Brgy, City)",
                  Icons.location_on_outlined,
                ),
                const SizedBox(height: 32),
                ClaySquishButton(
                  label: "Save Address",
                  primaryColor: _primaryViolet,
                  isLoading: _isSavingAddress,
                  onPressed: _saveAddress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboard(User user) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        isMobile
            ? Column(
                children: [
                  _buildProfileCard(user),
                  const SizedBox(height: 32),
                  _buildAddressCard(user),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildProfileCard(user)),
                  const SizedBox(width: 32),
                  Expanded(child: _buildAddressCard(user)),
                ],
              ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(40),
            boxShadow: _clayCardShadow,
          ),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 24.0 : 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Recent Orders",
                      style: GoogleFonts.nunito(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _darkText,
                        letterSpacing: -0.5,
                      ),
                    ),
                    InkWell(
                      onTap: () =>
                          setState(() => _currentTab = AccountTab.orderHistory),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _primaryVioletLight.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          "View All",
                          style: GoogleFonts.dmSans(
                            color: _primaryViolet,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                _buildOrderStreamTable(user.uid, limit: 5),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddressCard(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        boxShadow: _clayCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _secondaryOrange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: _secondaryOrange,
                size: 28,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "DELIVERY ADDRESS",
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _mutedText,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : "Customer Name",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                color: _darkText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _addressController.text.isNotEmpty
                  ? _addressController.text
                  : "No address provided yet.",
              style: GoogleFonts.dmSans(
                color: _mutedText,
                fontSize: 15,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => setState(() => _currentTab = AccountTab.settings),
              child: Text(
                "Edit Details",
                style: GoogleFonts.dmSans(
                  color: _primaryViolet,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHistory(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(48),
        boxShadow: _clayCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order History",
              style: GoogleFonts.nunito(
                fontSize: 32,
                fontWeight: FontWeight.w900,
                color: _darkText,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 40),
            _buildOrderStreamTable(user.uid),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(model.Order order) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(48),
        boxShadow: _clayCardShadow,
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? 24.0 : 48.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "Order Details",
                    style: GoogleFonts.nunito(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: _darkText,
                      letterSpacing: -1,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () =>
                      setState(() => _currentTab = AccountTab.orderHistory),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _primaryVioletLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: _primaryViolet,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${DateFormat('MMMM d, yyyy').format(order.createdAt)} • ${order.items.length} Products",
              style: GoogleFonts.dmSans(color: _mutedText, fontSize: 16),
            ),
            const SizedBox(height: 48),
            isMobile
                ? Column(
                    children: [
                      _buildBillingInfo(order),
                      const SizedBox(height: 32),
                      _buildOrderSummaryBox(order),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildBillingInfo(order)),
                      const SizedBox(width: 32),
                      Expanded(child: _buildOrderSummaryBox(order)),
                    ],
                  ),
            const SizedBox(height: 56),
            _buildFigmaTracker(order.status),
            const SizedBox(height: 56),
            Text(
              "ITEMS",
              style: GoogleFonts.nunito(
                fontSize: 12,
                fontWeight: FontWeight.w900,
                color: _mutedText,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade200, thickness: 2),
            const SizedBox(height: 16),
            ...order.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAE5F0),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: GoogleFonts.nunito(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: _darkText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₱${item.price.toStringAsFixed(2)} x ${item.quantity}",
                            style: GoogleFonts.dmSans(
                              color: _mutedText,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "₱${(item.price * item.quantity).toStringAsFixed(2)}",
                      style: GoogleFonts.nunito(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                        color: _primaryViolet,
                      ),
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

  Widget _buildBillingInfo(model.Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "BILLING ADDRESS",
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _mutedText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          order.customerName,
          style: GoogleFonts.nunito(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: _darkText,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          order.customerAddress,
          style: GoogleFonts.dmSans(
            color: _mutedText,
            fontSize: 15,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          "CONTACT",
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: _mutedText,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          FirebaseAuth.instance.currentUser?.email ?? "",
          style: GoogleFonts.dmSans(
            color: _darkText,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          order.customerPhone,
          style: GoogleFonts.dmSans(color: _mutedText, fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildOrderSummaryBox(model.Order order) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F1FA),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.black.withOpacity(0.03), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ORDER ID",
                style: GoogleFonts.nunito(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: _mutedText,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                "#${order.referenceId.split('-').last}",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300, thickness: 2, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Subtotal",
                style: GoogleFonts.dmSans(color: _mutedText, fontSize: 15),
              ),
              Text(
                "₱${order.total.toStringAsFixed(2)}",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: _darkText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Shipping",
                style: GoogleFonts.dmSans(color: _mutedText, fontSize: 15),
              ),
              Text(
                "Free",
                style: GoogleFonts.dmSans(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.grey.shade300, thickness: 2, height: 1),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total",
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: _darkText,
                ),
              ),
              Text(
                "₱${order.total.toStringAsFixed(2)}",
                style: GoogleFonts.nunito(
                  color: _primaryViolet,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  letterSpacing: -1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(User user) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(40),
        boxShadow: _clayCardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: _clayCardShadow,
                image: _profileImageUrl.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(_profileImageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _profileImageUrl.isEmpty
                  ? Icon(
                      Icons.person_rounded,
                      size: 48,
                      color: Colors.grey.shade300,
                    )
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              _nameController.text.isNotEmpty
                  ? _nameController.text
                  : "Customer Name",
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w900,
                fontSize: 22,
                color: _darkText,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Premium Member",
              style: GoogleFonts.dmSans(
                color: _primaryViolet,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () => setState(() => _currentTab = AccountTab.settings),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAE5F0),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Edit Profile",
                  style: GoogleFonts.dmSans(
                    color: _darkText,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStreamTable(String userId, {int? limit}) {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (limit != null) query = query.limit(limit);

    final isMobile = MediaQuery.of(context).size.width < 600;

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: _primaryViolet),
          );
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: Text(
                "No orders found yet.",
                style: GoogleFonts.dmSans(color: _mutedText, fontSize: 16),
              ),
            ),
          );
        }

        return Column(
          children: [
            if (!isMobile)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F1FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        "ORDER ID",
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _mutedText,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "DATE",
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _mutedText,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        "TOTAL",
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _mutedText,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        "STATUS",
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: _mutedText,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    const Expanded(flex: 2, child: SizedBox()),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            ...snapshot.data!.docs.map((doc) {
              final order = model.Order.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 24 : 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.03),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "#${order.referenceId.split('-').last}",
                                style: GoogleFonts.dmSans(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: _darkText,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _primaryVioletLight.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  order.status.toUpperCase(),
                                  style: GoogleFonts.nunito(
                                    color: _primaryViolet,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            DateFormat('d MMM, yyyy').format(order.createdAt),
                            style: GoogleFonts.dmSans(
                              color: _mutedText,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "₱${order.total.toStringAsFixed(2)}",
                                style: GoogleFonts.nunito(
                                  color: _darkText,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                ),
                              ),
                              InkWell(
                                onTap: () => setState(() {
                                  _selectedOrder = order;
                                  _currentTab = AccountTab.orderDetails;
                                }),
                                child: Text(
                                  "View Details",
                                  style: GoogleFonts.dmSans(
                                    color: _primaryViolet,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              "#${order.referenceId.split('-').last}",
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: _darkText,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              DateFormat('d MMM, yyyy').format(order.createdAt),
                              style: GoogleFonts.dmSans(
                                color: _mutedText,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              "₱${order.total.toStringAsFixed(2)}",
                              style: GoogleFonts.nunito(
                                color: _darkText,
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _primaryVioletLight.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: GoogleFonts.nunito(
                                  color: _primaryViolet,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: InkWell(
                                onTap: () => setState(() {
                                  _selectedOrder = order;
                                  _currentTab = AccountTab.orderDetails;
                                }),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.arrow_forward_ios_rounded,
                                    size: 14,
                                    color: _primaryViolet,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFigmaTracker(String status) {
    final steps = ['pending', 'processing', 'on the way', 'delivered'];
    int currentIndex = steps.indexOf(status.toLowerCase());
    if (currentIndex == -1) currentIndex = 0;

    if (status.toLowerCase() == 'cancelled') {
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            "Order Cancelled",
            style: GoogleFonts.nunito(
              color: Colors.red.shade700,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTrackerStep(Icons.check_rounded, "Received", 0, currentIndex),
        _buildTrackerLine(0, currentIndex),
        _buildTrackerStep(
          Icons.inventory_2_rounded,
          "Processing",
          1,
          currentIndex,
        ),
        _buildTrackerLine(1, currentIndex),
        _buildTrackerStep(
          Icons.local_shipping_rounded,
          "On the way",
          2,
          currentIndex,
        ),
        _buildTrackerLine(2, currentIndex),
        _buildTrackerStep(Icons.home_rounded, "Delivered", 3, currentIndex),
      ],
    );
  }

  Widget _buildTrackerStep(
    IconData icon,
    String label,
    int stepIndex,
    int currentIndex,
  ) {
    final isCompleted = currentIndex >= stepIndex;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Column(
      children: [
        Container(
          width: isMobile ? 48 : 64,
          height: isMobile ? 48 : 64,
          decoration: BoxDecoration(
            gradient: isCompleted
                ? LinearGradient(
                    colors: [_primaryVioletLight, _primaryViolet],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: isCompleted ? null : Colors.white,
            shape: BoxShape.circle,
            boxShadow: isCompleted
                ? [
                    BoxShadow(
                      color: _primaryViolet.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(4, 8),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
            border: Border.all(
              color: isCompleted
                  ? Colors.transparent
                  : Colors.black.withOpacity(0.05),
              width: 2,
            ),
          ),
          child: Icon(
            icon,
            color: isCompleted ? Colors.white : Colors.grey.shade400,
            size: isMobile ? 20 : 28,
          ),
        ),
        const SizedBox(height: 16),
        if (!isMobile)
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: isCompleted ? _primaryViolet : Colors.grey.shade400,
              fontWeight: isCompleted ? FontWeight.w900 : FontWeight.w700,
            ),
          ),
      ],
    );
  }

  Widget _buildTrackerLine(int stepIndex, int currentIndex) {
    final isCompleted = currentIndex > stepIndex;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Expanded(
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 0 : 36),
        height: 6,
        decoration: BoxDecoration(
          color: isCompleted ? _primaryViolet : const Color(0xFFEAE5F0),
          borderRadius: BorderRadius.circular(10),
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
  final VoidCallback onPressed;

  const ClaySquishButton({
    super.key,
    required this.label,
    required this.primaryColor,
    this.isLoading = false,
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
              : Text(
                  widget.label,
                  style: GoogleFonts.nunito(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
