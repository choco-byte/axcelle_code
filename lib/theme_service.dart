import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class ThemeService {
  static const String _themeKey = 'isDarkMode';

static String getThemeKey() => _themeKey; 

  final _themeController = StreamController<bool>.broadcast();

  Stream<bool> get themeStream => _themeController.stream;

  ThemeService() {
    _loadTheme();
  }

  void _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDarkMode = prefs.getBool(_themeKey) ?? false;
    
    print('THEME SERVICE: Nilai awal tema yang dibaca: $isDarkMode'); 
    
    _themeController.sink.add(isDarkMode); 
  }

  Future<void> toggleTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_themeKey); 
    await prefs.setBool(_themeKey, isDarkMode); 
    _themeController.sink.add(isDarkMode); 
  }
  
  void dispose() {
    _themeController.close();
  }
}

final themeService = ThemeService();