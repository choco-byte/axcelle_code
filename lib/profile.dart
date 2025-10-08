import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:axcelle_code/theme_service.dart';
import 'package:axcelle_code/login.dart';
import 'package:axcelle_code/main.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _isDarkMode = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInitialThemeStatus();
  }

  void _loadInitialThemeStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMode = prefs.getBool(ThemeService.getThemeKey()) ?? false;

    if (mounted) {
      setState(() {
        _isDarkMode = savedMode;
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    navigatorKey.currentState!.pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
  
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Theme Settings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Dark Mode Active'),
              value: _isDarkMode,
              onChanged: (newValue) {
                setState(() {
                  _isDarkMode = newValue;
                });
                themeService.toggleTheme(newValue);
              },
            ),
            const Divider(),
            const SizedBox(height: 30),

            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
