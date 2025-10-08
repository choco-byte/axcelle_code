import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axcelle_code/login.dart';
import 'package:axcelle_code/navigator.dart';
import 'package:axcelle_code/theme_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<bool> _isLoggedInFuture;

  @override
  void initState() {
    super.initState();
    _isLoggedInFuture = _checkLoginStatus();
  }

  Future<bool> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: themeService.themeStream,
      initialData: false,
      builder: (context, themeSnapshot) {
        final isDarkMode = themeSnapshot.data ?? false;

        return MaterialApp(
          title: 'Eclipse',
          debugShowCheckedModeBanner: false,
          navigatorKey: navigatorKey,
          theme: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
          home: FutureBuilder<bool>(
            future: _isLoggedInFuture,
            builder: (context, loginSnapshot) {
              if (loginSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (loginSnapshot.data == true) {
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
    colorScheme: ColorScheme.light().copyWith(
      primary: primaryColor,
      secondary: primaryColor,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: primaryColor,
      unselectedItemColor: Colors.grey,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return null;
      }),
    ),
  );
}

ThemeData _buildDarkTheme() {
  const Color primaryColor = Color(0xFF7B1113);
  const Color darkBackground = Color(0xFF1A1A1A);
  const Color darkSurface = Color(0xFF2C2C2C);

  return ThemeData.dark().copyWith(
    colorScheme: const ColorScheme.dark(
      primary: primaryColor,
      secondary: primaryColor,
      surface: darkSurface,
      onSurface: Color(0xFFE0E0E0),
    ),
    scaffoldBackgroundColor: darkBackground,
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      foregroundColor: Color(0xFFE0E0E0),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: darkBackground,
      selectedItemColor: primaryColor,
      unselectedItemColor: Color(0xFFB0B0B0),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primaryColor;
        }
        return null;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
    ),
    cardTheme: const CardThemeData(
      color: darkSurface,
    ),
  );
}
