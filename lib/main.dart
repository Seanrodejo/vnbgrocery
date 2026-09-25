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

// --- WEB SCROLL FIX ---
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

// --- PREMIUM GLOBAL PAGE TRANSITIONS ---
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
        // MOBILE RESPONSIVE FIX: Clamps text scaling so UI doesn't break on accessibility settings
        builder: (context, child) {
          final mediaQueryData = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQueryData.copyWith(
              // Using TextScaler clamped between 0.8 and 1.2 to prevent UI breaking
              textScaler: TextScaler.linear(
                MediaQuery.textScaleFactorOf(context).clamp(0.8, 1.2),
              ),
            ),
            child: child!,
          );
        },
        theme: ThemeData(
          useMaterial3: true,
          // CLAYMORPHISM GLOBAL FONTS (Body Text)
          fontFamily: GoogleFonts.dmSans().fontFamily,
          // CLAYMORPHISM CANVAS COLOR
          scaffoldBackgroundColor: const Color(0xFFF4F1FA),
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF7C3AED), // CLAYMORPHISM PRIMARY VIOLET
            onPrimary: Colors.white,
            secondary: Color(0xFFDB2777), // CLAYMORPHISM HOT PINK
            onSecondary: Colors.white,
            surface: Color(0xFFF4F1FA), // CLAYMORPHISM CANVAS
            onSurface: Color(0xFF332F3A), // CLAYMORPHISM DARK TEXT
            error: Color(0xFFD0011B),
            onError: Colors.white,
            brightness: Brightness.light,
          ),
          // FLOATING SNACKBAR THEME (Match Claymorphism Aesthetics)
          snackBarTheme: SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF332F3A),
            contentTextStyle: GoogleFonts.dmSans(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          // SUBTLE DIVIDER THEME
          dividerTheme: DividerThemeData(
            color: Colors.grey.shade200,
            thickness: 2,
            space: 1,
          ),
        ),
        routerConfig: _router,
      ),
    );
  }
}
