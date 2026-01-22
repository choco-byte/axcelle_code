import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:axcelle_code/theme_service.dart';
import 'package:axcelle_code/login.dart';
import 'package:axcelle_code/main.dart';
import 'package:axcelle_code/watchlist_screen.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool _isDarkMode = false;
  bool _isLoading = true;

  String _displayName = '';
  String _email = '';
  String _photoUrl = '';
  int _watchlistCount = 0;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _initProfile();
  }

  Future<void> _initProfile() async {
    await _loadTheme();
    await _loadUserProfile();
    await _loadWatchlistCount();

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(ThemeService.getThemeKey()) ?? false;
  }

  Future<void> _loadUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final doc =
        await _firestore.collection('users').doc(user.uid).get();

    if (!doc.exists) return;

    final data = doc.data()!;
    _displayName = data['username'] ?? 'User';
    _email = data['email'] ?? user.email ?? '';
    _photoUrl = data['photoUrl'] ?? '';
  }

  Future<void> _loadWatchlistCount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('watchlist')
        .get();

    _watchlistCount = snapshot.docs.length;
  }

  Future<void> _logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      await FirebaseAuth.instance.signOut();

      if (!mounted) return;
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Berhasil logout.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal logout.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 PROFILE HEADER
          Column(
            children: [
              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.grey.shade300,
                backgroundImage:
                    _photoUrl.isNotEmpty ? NetworkImage(_photoUrl) : null,
                child: _photoUrl.isEmpty
                    ? const Icon(Icons.person, size: 45, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                _displayName,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // 🔹 THEME
          const Text(
            'Theme Settings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Dark Mode Active'),
            value: _isDarkMode,
            onChanged: (value) {
              setState(() => _isDarkMode = value);
              themeService.toggleTheme(value);
            },
          ),

          const Divider(),

          ListTile(
            leading: const Icon(Icons.bookmark, color: Colors.blue),
            title: const Text('My Watchlist'),
            subtitle: Text('$_watchlistCount items'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const WatchlistScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 40),

          Center(
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
