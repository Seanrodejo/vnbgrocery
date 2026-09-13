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

// --- 🔥 PREMIUM GLOBAL PAGE TRANSITIONS 🔥 ---
CustomTransitionPage buildPageWithAnimation<T>({
  required BuildContext context,
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOutCirc).animate(animation),
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.02, 0.05), // Subtle slide up and left
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: child,
        ),
      );
    },
  );
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      pageBuilder: (context, state) => buildPageWithAnimation(
        context: context,
        state: state,
        child: const CatalogScreen(),
      ),
    ),
    GoRoute(
      path: '/cart',
      pageBuilder: (context, state) => buildPageWithAnimation(
        context: context,
        state: state,
        child: const CartScreen(),
      ),
    ),
    GoRoute(
      path: '/admin',
      pageBuilder: (context, state) => buildPageWithAnimation(
        context: context,
        state: state,
        child: const AdminScreen(),
      ),
    ),
    GoRoute(
      path: '/login',
      pageBuilder: (context, state) => buildPageWithAnimation(
        context: context,
        state: state,
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/register',
      pageBuilder: (context, state) => buildPageWithAnimation(
        context: context,
        state: state,
        child: const RegisterScreen(),
      ),
    ),
    GoRoute(
      path: '/orders',
      pageBuilder: (context, state) => buildPageWithAnimation(
        context: context,
        state: state,
        child: const ClientOrdersScreen(),
      ),
    ),
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
        // 🔥 MOBILE RESPONSIVE FIX: Clamps text scaling so UI doesn't break on accessibility settings
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(
              textScaler: TextScaler.linear(
                mediaQueryData.textScaleFactor.clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: GoogleFonts.poppins().fontFamily,
          scaffoldBackgroundColor: const Color(
            0xFFF4F5F7,
          ), // Elevated clean grey
          colorScheme: const ColorScheme(
            primary: Color(0xFF7634C8), // FIGMA PRIMARY PURPLE
            onPrimary: Colors.white,
            secondary: Color(0xFFFF9D42), // FIGMA SECONDARY ORANGE
            onSecondary: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1A1A1A), // Darker, crisper text color
            error: Color(0xFFD0011B),
            onError: Colors.white,
            brightness: Brightness.light,
          ),

          // 1. Premium AppBar Theme
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1A1A1A),
            elevation: 0,
            centerTitle: true,
            surfaceTintColor: Colors.transparent,
            iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
          ),

          // 2. Premium Card Theme
          cardTheme: CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withOpacity(0.08),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24), // Smoother borders
              side: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            margin: const EdgeInsets.all(8),
          ),

          // 3. Floating SnackBar Theme
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF1A1A1A),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // 4. Subtle Divider Theme
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade200,
            thickness: 1,
            space: 1,
          ),

          // 5. Figma Input Decoration Theme
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFF7634C8), width: 2),
            ),
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontFamily: 'Poppins',
            ),
            labelStyle: TextStyle(
              color: Colors.grey.shade600,
              fontFamily: 'Poppins',
            ),
          ),

          // 6. Figma Elevated Button Theme
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7634C8),
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: const Color(0xFF7634C8).withOpacity(0.4),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                fontFamily: 'Poppins',
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
