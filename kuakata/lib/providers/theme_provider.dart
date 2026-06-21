import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = false; // default theme is light mode

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider() {
    _loadThemePreference();
  }

  // Load theme preference from SharedPreferences
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool('is_dark_mode') ?? false;
    notifyListeners();
  }

  // Toggle theme mode and save to SharedPreferences
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }

  // Set specific theme mode
  Future<void> setTheme(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_mode', _isDarkMode);
    notifyListeners();
  }
}
