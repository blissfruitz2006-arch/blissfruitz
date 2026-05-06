import 'package:flutter/material.dart';

const Color _riderPrimary = Color(0xFFE65100);
const Color _riderSecondary = Color(0xFFFFB300);
const Color _riderAppBarColor = Color(0xFF1A237E);
const Color _bgLight = Color(0xFFFAFAFA);
const Color _bgDark = Color(0xFF0D0D0D);
const Color _surfaceLight = Color(0xFFF0F0F0);
const Color _surfaceDark = Color(0xFF1A1A1A);

final ThemeData riderLightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _riderPrimary,
    primary: _riderPrimary,
    secondary: _riderSecondary,
    surface: _surfaceLight,
    onSurface: Colors.black,
  ),
  scaffoldBackgroundColor: _bgLight,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.black),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _riderAppBarColor,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: _riderPrimary,
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    showSelectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _riderPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54), // Full-width feel
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return _riderPrimary;
      }
      return null;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return _riderPrimary.withValues(alpha: 0.5);
      }
      return null;
    }),
  ),
  badgeTheme: const BadgeThemeData(
    backgroundColor: _riderSecondary,
    textColor: Colors.black,
  ),
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
);

final ThemeData riderDarkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: _riderPrimary,
    brightness: Brightness.dark,
    primary: _riderPrimary,
    secondary: _riderSecondary,
    surface: _surfaceDark,
    onSurface: Colors.white,
  ),
  scaffoldBackgroundColor: _bgDark,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(fontSize: 16, color: Colors.white),
    bodyMedium: TextStyle(fontSize: 16, color: Colors.white70),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: _riderAppBarColor,
    elevation: 0,
    centerTitle: true,
    iconTheme: IconThemeData(color: Colors.white),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: 18,
      fontWeight: FontWeight.w600,
    ),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: _surfaceDark,
    selectedItemColor: _riderPrimary,
    unselectedItemColor: Colors.grey,
    showUnselectedLabels: true,
    showSelectedLabels: true,
    type: BottomNavigationBarType.fixed,
    elevation: 8,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: _riderPrimary,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(54), // Full-width feel
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  switchTheme: SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return _riderPrimary;
      }
      return null;
    }),
  ),
  badgeTheme: const BadgeThemeData(
    backgroundColor: _riderSecondary,
    textColor: Colors.black,
  ),
  cardTheme: CardThemeData(
    color: _surfaceDark,
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    ),
  ),
);

