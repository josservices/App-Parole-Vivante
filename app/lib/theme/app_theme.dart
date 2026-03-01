import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const double maxContentWidth = 1100;
  static const double spacingXs = 8;
  static const double spacingSm = 12;
  static const double spacingMd = 16;

  static ThemeData lightTheme(TextTheme textTheme) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1B8A5A)),
      useMaterial3: true,
      textTheme: textTheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFFF4F8F5),
      navigationRailTheme: const NavigationRailThemeData(
        minWidth: 72,
        minExtendedWidth: 240,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 72,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(spacingSm),
      ),
    );
  }

  static ThemeData darkTheme(TextTheme textTheme) {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF1B8A5A),
        brightness: Brightness.dark,
      ),
      useMaterial3: true,
      textTheme: textTheme,
    );

    return base.copyWith(
      navigationRailTheme: const NavigationRailThemeData(
        minWidth: 72,
        minExtendedWidth: 240,
      ),
      navigationBarTheme: base.navigationBarTheme.copyWith(
        height: 72,
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.all(spacingSm),
      ),
    );
  }
}
