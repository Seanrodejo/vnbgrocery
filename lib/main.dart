import 'dart:ui'; 
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';

import 'screens/catalog_screen.dart';
import 'screens/cart_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/client_orders_screen.dart';

// 🔥 WEB SCROLL FIX 🔥
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse, 
  };
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
  } catch (e) {
    debugPrint("Firebase Verification Error: $e");
  }

  runApp(const MyApp());
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const CatalogScreen()),
    GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
    GoRoute(path: '/admin', builder: (context, state) => const AdminScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/register', builder: (context, state) => const RegisterScreen()),
    GoRoute(path: '/orders', builder: (context, state) => const ClientOrdersScreen()),
  ],
);

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => CartProvider())],
      child: MaterialApp.router(
        title: 'VN Brigade Groceries PH',
        debugShowCheckedModeBanner: false,
        scrollBehavior: MyCustomScrollBehavior(), 
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5), // Shopee Light Grey
          
          colorScheme: const ColorScheme(
            primary: Color(0xFFEE4D2D), // 🔥 SHOPEE ORANGE
            onPrimary: Colors.white,
            secondary: Color(0xFFEE4D2D),
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black87,
            error: Color(0xFFD0011B),
            onError: Colors.white,
            brightness: Brightness.light,
          ),

          // --- 🌟 NEW ENHANCEMENTS START HERE 🌟 ---
          
          // 1. Premium AppBar Theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0, // Flat modern look
            centerTitle: true,
            surfaceTintColor: Colors.transparent, // Stops M3 from tinting the appbar on scroll
            iconTheme: IconThemeData(color: Color(0xFFEE4D2D)),
          ),

          // 2. Premium Card Theme (For Product Grids)
          // FIXED: Changed CardTheme to CardThemeData for stricter Flutter SDK rules
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 2,
            shadowColor: Colors.black.withOpacity(0.08), // Very subtle soft shadow
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Smooth modern corners
              side: BorderSide(color: Colors.grey.shade200, width: 1), // Crisp edge
            ),
            margin: const EdgeInsets.all(8),
          ),

          // 3. Floating SnackBar Theme (For "Added to cart" notifications)
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF333333),
            contentTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),

          // 4. Subtle Divider Theme to keep lists looking clean
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade300,
            thickness: 1,
            space: 1,
          ),

          // --- 🌟 NEW ENHANCEMENTS END HERE 🌟 ---
          
          // Existing Input Decoration Theme (Untouched)
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4), 
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: Color(0xFFEE4D2D)),
            ),
          ),

          // Enhanced Elevated Button Theme (Kept your logic, added padding/textStyle)
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEE4D2D),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), // Added: Thicker, more clickable buttons
              textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16), // Added: Bolder button text
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)
              ), 
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}