import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  bool _isLoading = false;
  bool _keepSignedIn = true;
  bool _obscurePassword = true;

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

  void _login() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) context.go('/');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Login Failed: ${e.toString()}",
            style: GoogleFonts.dmSans(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
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
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _primaryViolet.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_reset_rounded,
                    size: 48,
                    color: _primaryViolet,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Reset Password",
                  style: GoogleFonts.nunito(
                    fontWeight: FontWeight.w900,
                    fontSize: 28,
                    color: _darkText,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter your email address and we'll send you a link to reset your password.",
                  style: GoogleFonts.dmSans(
                    color: _mutedText,
                    height: 1.5,
                    fontSize: 15,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
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
                    controller: resetEmailController,
                    style: GoogleFonts.dmSans(
                      fontSize: 16,
                      color: _darkText,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      labelText: "Email Address",
                      prefixIcon: Icon(
                        Icons.email_rounded,
                        color: _primaryViolet,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 18,
                      ),
                      labelStyle: GoogleFonts.dmSans(color: _mutedText),
                    ),
                  ),
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
                        label: "Send Link",
                        primaryColor: _primaryViolet,
                        onPressed: () async {
                          if (resetEmailController.text.isEmpty) return;
                          try {
                            await FirebaseAuth.instance.sendPasswordResetEmail(
                              email: resetEmailController.text.trim(),
                            );
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Reset link sent! Check your email.",
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
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Error: ${e.toString()}",
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
                          }
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
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: _canvas,
      body: Stack(
        children: [
          // --- CLAYMORPHISM ANIMATED BLOBS BACKGROUND ---
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

          // --- MAIN LOGIN CARD ---
          Center(
            // FIXED: Binalot ng SingleChildScrollView para hindi mag-overflow
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * (1 - value)),
                    child: Opacity(opacity: value, child: child),
                  );
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(48), // Super rounded
                      boxShadow: _clayCardShadow,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(48),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 32.0 : 48.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // BRANDING
                              RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: GoogleFonts.nunito(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 26,
                                    letterSpacing: -0.5,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: 'VN BRIGADE\n',
                                      style: TextStyle(
                                        color: _secondaryOrange,
                                        fontSize: 20,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'GROCERIES ',
                                      style: TextStyle(color: _primaryViolet),
                                    ),
                                    TextSpan(
                                      text: 'PH',
                                      style: TextStyle(color: _darkText),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 40),

                              Text(
                                "Welcome Back",
                                style: GoogleFonts.nunito(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: _darkText,
                                  letterSpacing: -1,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Log in to your premium account",
                                style: GoogleFonts.dmSans(
                                  color: _mutedText,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // EMAIL FIELD
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
                                  controller: _emailController,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    color: _darkText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Email Address",
                                    prefixIcon: Icon(
                                      Icons.email_rounded,
                                      color: _primaryViolet,
                                      size: 22,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 18,
                                    ),
                                    labelStyle: GoogleFonts.dmSans(
                                      color: _mutedText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // PASSWORD FIELD
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
                                  obscureText: _obscurePassword,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 16,
                                    color: _darkText,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: "Password",
                                    prefixIcon: Icon(
                                      Icons.lock_rounded,
                                      color: _primaryViolet,
                                      size: 22,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_rounded
                                            : Icons.visibility_rounded,
                                        color: _mutedText,
                                        size: 22,
                                      ),
                                      onPressed: () => setState(
                                        () => _obscurePassword =
                                            !_obscurePassword,
                                      ),
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 18,
                                    ),
                                    labelStyle: GoogleFonts.dmSans(
                                      color: _mutedText,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // OPTIONS ROW
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _keepSignedIn,
                                      activeColor: _primaryViolet,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      side: BorderSide(
                                        color: Colors.grey.shade400,
                                        width: 2,
                                      ),
                                      onChanged: (val) =>
                                          setState(() => _keepSignedIn = val!),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    "Remember me",
                                    style: GoogleFonts.dmSans(
                                      color: _darkText,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  GestureDetector(
                                    onTap: _showForgotPasswordDialog,
                                    child: Text(
                                      "Forgot Password?",
                                      style: GoogleFonts.dmSans(
                                        color: _primaryViolet,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 48),

                              // LOGIN SQUISH BUTTON
                              ClaySquishButton(
                                label: "Log In",
                                primaryColor: _primaryViolet,
                                isLoading: _isLoading,
                                onPressed: _login,
                              ),
                              const SizedBox(height: 32),

                              // GUEST BUTTON
                              ClaySquishButton(
                                label: "Continue as Guest",
                                primaryColor: _secondaryOrange,
                                icon: Icons.person_outline_rounded,
                                onPressed: () => context.go('/'),
                              ),
                              const SizedBox(height: 32),

                              // REGISTER LINK
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "New here? ",
                                    style: GoogleFonts.dmSans(
                                      color: _mutedText,
                                      fontSize: 15,
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () => context.go('/register'),
                                    child: Text(
                                      "Create an Account",
                                      style: GoogleFonts.dmSans(
                                        color: _secondaryOrange,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
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
                ),
              ),
            ),
          ),
        ],
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
