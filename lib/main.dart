import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login.dart';
import 'navigator.dart';
import 'theme_service.dart';
import 'notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  // ADMOB
  await MobileAds.instance.initialize();

  // ANALYTICS
  await FirebaseAnalytics.instance.logEvent(
    name: 'app_start',
    parameters: {'success': 'true'},
  );

  // 🔔 INIT NOTIFICATION
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: themeService.themeStream,
      initialData: false,
      builder: (context, snapshot) {
        final isDark = snapshot.data ?? false;

        return MaterialApp(
          title: 'Firebase Auth Demo',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: isDark ? _buildDarkTheme() : _buildLightTheme(),
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasData) {
                return Nav();
              } else {
                return const LoginScreen();
              }
            },
          ),
        );
      },
    );
  }
}

ThemeData _buildLightTheme() {
  const Color primaryColor = Color(0xFF7B1113);
  return ThemeData.light().copyWith(
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: primaryColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
  );
}

ThemeData _buildDarkTheme() {
  const Color primaryColor = Color(0xFF7B1113);
  const Color darkBackground = Color(0xFF1A1A1A);
  const Color darkSurface = Color(0xFF2C2C2C);

  return ThemeData.dark().copyWith(
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: darkSurface,
      onSurface: Color(0xFFE0E0E0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Color(0xFFE0E0E0),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackground,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFFB0B0B0),
    ),
  );
}