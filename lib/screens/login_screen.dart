import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; // REQUIRED
import 'package:go_router/go_router.dart';
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
        SnackBar(content: Text("Login Failed: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- NEW: FORGOT PASSWORD DIALOG ---
  void _showForgotPasswordDialog() {
    final resetEmailController = TextEditingController();
    final primaryColor = const Color(0xFFEE4D2D); // ADDED: Brand Color
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // ADDED: Premium rounded dialog
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent, // ADDED: Prevents Material 3 purple tint
        title: const Text("Reset Password", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20)), // ADDED: Bolder title
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Enter your email address and we'll send you a link to reset your password.",
              style: TextStyle(color: Colors.grey.shade600, height: 1.4), // ADDED: Better line height and color
            ),
            const SizedBox(height: 24), // ADDED: More spacing
            TextField(
              controller: resetEmailController,
              decoration: InputDecoration( // ADDED: Upgraded Input Decoration to match app theme
                labelText: "Email Address", 
                prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 24, bottom: 24, left: 24), // ADDED: Better action padding
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), // ADDED: Better tap target
            ),
            child: const Text("Cancel", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (resetEmailController.text.isEmpty) return;
              try {
                // Firebase built-in reset function
                await FirebaseAuth.instance.sendPasswordResetEmail(email: resetEmailController.text.trim());
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Reset link sent! Check your email."), backgroundColor: Colors.green),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error: ${e.toString()}"), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Send Link", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFEE4D2D); // ADDED: Standardized Brand Orange

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Welcome Back", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), // ADDED: Bolder title
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87, // ADDED: Ensure text is dark
        elevation: 0,
        centerTitle: true,
        leading: IconButton( // ADDED: Modern back button for easy navigation
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container( // ADDED: Wrapped Card in Container for exact shadow control
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, spreadRadius: 4, offset: const Offset(0, 8)) // ADDED: Premium dispersed shadow
                ]
              ),
              child: Card(
                elevation: 0, // ADDED: Disabled default card elevation to use custom shadow above
                color: Colors.white,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20), // ADDED: Larger padding for the icon
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08), // ADDED: Switched to main brand color
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_outline, size: 64, color: primaryColor), // ADDED: Switched to main brand color
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Login to Your Account",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3436), letterSpacing: -0.5), // ADDED: Tighter, bolder heading
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Access your orders and discounts",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500), // ADDED: Better subtitle styling
                      ),
                      const SizedBox(height: 32),
                      
                      TextField(
                        controller: _emailController,
                        decoration: InputDecoration( // ADDED: Upgraded Input Decoration
                          labelText: "Email Address",
                          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // ADDED: Taller input fields
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration( // ADDED: Upgraded Input Decoration
                          labelText: "Password",
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.grey.shade600),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: primaryColor)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18), // ADDED: Taller input fields
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Row(
                        children: [
                          SizedBox( // ADDED: Constrained checkbox size
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _keepSignedIn,
                              activeColor: primaryColor, // ADDED: Matched brand color
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)), // ADDED: Rounded checkbox
                              onChanged: (val) => setState(() => _keepSignedIn = val!),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text("Keep me signed in", style: TextStyle(color: Colors.grey.shade700, fontSize: 13, fontWeight: FontWeight.w500)), // ADDED: Better font styling
                          const Spacer(),
                          
                          // UPDATED: Now clickable
                          TextButton(
                            onPressed: _showForgotPasswordDialog,
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero), // ADDED: Removes default padding for perfect alignment
                            child: const Text("Forgot Password?", style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600, fontSize: 13)), // ADDED: Darker, bolder text
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 32), // ADDED: More spacing before button
                      SizedBox(
                        width: double.infinity,
                        height: 56, // ADDED: Taller button
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // ADDED: Matched brand color
                            foregroundColor: Colors.white,
                            elevation: 4, // ADDED: Standardized elevation
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // ADDED: Smoother button corners
                          ),
                          child: _isLoading 
                              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)) // ADDED: Sized the loader properly
                              : const Text("LOGIN SECURELY", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)), // ADDED: Bolder button text
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("New here? ", style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(
                              "Create an Account",
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800), // ADDED: Matched brand color and made bolder
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16), // ADDED: More spacing
                      TextButton(
                        onPressed: () => context.go('/'),
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // ADDED: Rounded ripple effect
                        ),
                        child: Text("Continue as Guest", style: TextStyle(color: Colors.grey.shade500, fontWeight: FontWeight.w600)), // ADDED: Styled text
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}