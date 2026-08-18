import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  void _register() async {
    setState(() => _isLoading = true);
    try {
      await _authService.signUp(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Account Created! Please Login.")),
        );
        context.go('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFEE4D2D); // ADDED: Standardized Brand Orange

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // ADDED: Match login screen background
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)), // ADDED: Bolder title
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        leading: IconButton( // ADDED: Modern back button
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center( // ADDED: Centered layout matching the login screen
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Container( // ADDED: Wrapped Card for shadow control
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 24, spreadRadius: 4, offset: const Offset(0, 8)) // ADDED: Premium dispersed shadow
                ]
              ),
              child: Card(
                elevation: 0, // ADDED: Elevation handled by Container shadow
                color: Colors.white,
                margin: EdgeInsets.zero,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0), // ADDED: More breathing room inside the card
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container( // ADDED: Branded icon header
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.person_add_alt_1, size: 64, color: primaryColor),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        "Join VNB Groceries", 
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF2D3436), letterSpacing: -0.5) // ADDED: Bolder typography
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Create an account to track your orders",
                        style: TextStyle(color: Colors.grey[500], fontSize: 14, fontWeight: FontWeight.w500), // ADDED: Subtitle
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                        ),
                      ),
                      const SizedBox(height: 32), // ADDED: Increased spacing before button
                      
                      SizedBox(
                        width: double.infinity,
                        height: 56, // ADDED: Taller button
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor, // ADDED: Standardized brand color
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: primaryColor.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // ADDED: Smoother button corners
                          ),
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading 
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.0)), // ADDED: Bolder button text
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      Row( // ADDED: Easy navigation back to login
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Already have an account? ", style: TextStyle(color: Colors.black54)),
                          GestureDetector(
                            onTap: () => context.go('/login'),
                            child: Text(
                              "Login",
                              style: TextStyle(color: primaryColor, fontWeight: FontWeight.w800),
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
    );
  }
}