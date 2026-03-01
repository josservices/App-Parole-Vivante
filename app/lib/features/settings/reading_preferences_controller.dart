import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReadingPreferencesController extends ChangeNotifier {
  static const _textSizeKey = 'reading_text_size';
  static const _lineHeightKey = 'reading_line_height';
  static const _themeModeKey = 'reading_theme_mode';

  double _textSize = 18;
  double _lineHeight = 1.45;
  ThemeMode _themeMode = ThemeMode.system;

  double get textSize => _textSize;
  double get lineHeight => _lineHeight;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _textSize = prefs.getDouble(_textSizeKey) ?? 18;
    _lineHeight = prefs.getDouble(_lineHeightKey) ?? 1.45;
    final rawMode = prefs.getString(_themeModeKey) ?? ThemeMode.system.name;
    _themeMode = ThemeMode.values.firstWhere(
      (mode) => mode.name == rawMode,
      orElse: () => ThemeMode.system,
    );
    notifyListeners();
  }

  Future<void> setTextSize(double value) async {
    _textSize = value.clamp(14, 28);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_textSizeKey, _textSize);
  }

  Future<void> setLineHeight(double value) async {
    _lineHeight = value.clamp(1.2, 2.2);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_lineHeightKey, _lineHeight);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeModeKey, mode.name);
  }
}
