import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeNotifier with ChangeNotifier {
  ThemeData _currentTheme;
  final String key = "theme";
  SharedPreferences? _prefs;

  ThemeNotifier() : _currentTheme = yellowTheme {
    _loadFromPrefs();
  }

  ThemeData get currentTheme => _currentTheme;

  Future<void> toggleTheme() async {
    _currentTheme = (_currentTheme == yellowTheme) ? blackTheme : yellowTheme;
    await _saveToPrefs(_currentTheme == yellowTheme ? 'yellow' : 'black');
    notifyListeners();
  }

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> _loadFromPrefs() async {
    await _initPrefs();
    final themeStr = _prefs!.getString(key) ?? 'yellow';
    _currentTheme = (themeStr == 'black') ? blackTheme : yellowTheme;
    notifyListeners();
  }

  Future<void> _saveToPrefs(String themeStr) async {
    await _initPrefs();
    await _prefs!.setString(key, themeStr);
  }
}

ThemeData yellowTheme = ThemeData(
  primaryColor: Color.fromARGB(255, 35, 74, 246),
  hintColor: const Color.fromARGB(255, 249, 248, 248),
  scaffoldBackgroundColor: const Color.fromARGB(255, 35, 74, 246),
  // Define other text styles as needed
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: const Color.fromARGB(255, 35, 74, 246),
    selectedItemColor: Colors.black,
    unselectedItemColor: Colors.white, // Or any other color
  ),
  // Add other customizations as needed
);

ThemeData blackTheme = ThemeData(
  primaryColor: Color.fromARGB(255, 255, 255, 255),
  hintColor: const Color.fromARGB(255, 35, 74, 246),
  scaffoldBackgroundColor: Colors.black,
  // Define other text styles as needed
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color.fromARGB(255, 47, 47, 48),
    selectedItemColor: const Color.fromARGB(255, 35, 74, 246),
    unselectedItemColor: Colors.white, // Or any other color
  ),
  // Add other customizations as needed
);

