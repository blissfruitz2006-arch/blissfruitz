import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Core Branding ───
  static const Color primary = Color(0xFF176a21); // Forest Green
  static const Color primaryDim = Color(0xFF025d16);
  static const Color primaryContainer = Color(0xFF9df197);
  static const Color onPrimary = Color(0xFFd1ffc8);
  static const Color onPrimaryContainer = Color(0xFF005c15);

  static const Color secondary = Color(0xFF874e00); // Earthy Amber
  static const Color secondaryContainer = Color(0xFFffc791);
  static const Color onSecondaryContainer = Color(0xFF6a3c00);

  static const Color tertiary = Color(0xFFb71211); // Deep Red
  static const Color tertiaryContainer = Color(0xFFff9385);

  // ─── Neutral Palette (Light) ───
  static const Color surface = Color(0xFFF9FAFB);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F4F6);
  static const Color surfaceContainer = Color(0xFFE5E7EB);
  static const Color onSurface = Color(0xFF111827);
  static const Color onSurfaceVariant = Color(0xFF4B5563);
  static const Color outline = Color(0xFFD1D5DB);
  static const Color outlineVariant = Color(0xFFE5E7EB);

  // ─── Neutral Palette (Dark) ───
  static const Color darkSurface = Color(0xFF030712);
  static const Color darkSurfaceContainerLowest = Color(0xFF0F172A);
  static const Color darkSurfaceContainerLow = Color(0xFF1E293B);
  static const Color darkSurfaceContainer = Color(0xFF334155);
  static const Color darkOnSurface = Color(0xFFF9FAFB);
  static const Color darkOnSurfaceVariant = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0xFF334155);
  static const Color error = Color(0xFFdc2626);
  static const Color lightSurfaceContainerHigh = Color(0xFFE5E7EB);
  static const Color darkSurfaceContainerHigh = Color(0xFF1E293B);

  // ─── Design Utilities ───
  static const double borderRadius = 24.0;
  static const double borderRadiusLarge = 36.0;

  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
  ];

  static List<BoxShadow> premiumShadow = [
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, primaryDim],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient glassGradient(bool isDark) {
    return LinearGradient(
      colors: isDark 
        ? [Colors.white.withValues(alpha: 0.1), Colors.white.withValues(alpha: 0.05)]
        : [Colors.white.withValues(alpha: 0.8), Colors.white.withValues(alpha: 0.4)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
  }

  // Legacy for compatibility
  static const Color primaryGreen = primary;
  static const Color primaryGreenLight = primaryContainer;
  static const Color accentAmber = secondaryContainer;

  // ─── Typography ───
  static TextTheme _buildTextTheme(TextTheme base, Color textColor) {
    final bodyTheme = GoogleFonts.beVietnamProTextTheme(base);
    return bodyTheme.copyWith(
      displayLarge: GoogleFonts.outfit(
        textStyle: bodyTheme.displayLarge,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -1.5,
      ),
      headlineLarge: GoogleFonts.outfit(
        textStyle: bodyTheme.headlineLarge,
        fontWeight: FontWeight.w800,
        color: textColor,
        letterSpacing: -1.0,
      ),
      titleLarge: GoogleFonts.outfit(
        textStyle: bodyTheme.titleLarge,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
      titleMedium: GoogleFonts.outfit(
        textStyle: bodyTheme.titleMedium,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      labelLarge: GoogleFonts.outfit(
        textStyle: bodyTheme.labelLarge,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }

  static ThemeData get lightTheme {
    final base = ThemeData.light(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.light(
        primary: primary,
        onPrimary: Colors.white,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        secondary: secondary,
        onSecondary: Colors.white,
        secondaryContainer: secondaryContainer,
        onSecondaryContainer: onSecondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        surface: surfaceContainerLowest,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
        outline: outline,
        outlineVariant: outlineVariant,
        surfaceContainerHigh: lightSurfaceContainerHigh,
        error: error,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: _buildTextTheme(base.textTheme, onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: onSurface),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: onSurface,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: const BorderSide(color: outlineVariant, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }

  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      colorScheme: const ColorScheme.dark(
        primary: primaryContainer,
        onPrimary: onPrimaryContainer,
        primaryContainer: primary,
        onPrimaryContainer: Colors.white,
        secondary: secondaryContainer,
        onSecondary: onSecondaryContainer,
        surface: darkSurfaceContainerLowest,
        onSurface: darkOnSurface,
        onSurfaceVariant: darkOnSurfaceVariant,
        outline: darkOutline,
        outlineVariant: Color(0xFF1E293B),
        surfaceContainerHigh: darkSurfaceContainerHigh,
        error: error,
      ),
      scaffoldBackgroundColor: darkSurface,
      textTheme: _buildTextTheme(base.textTheme, darkOnSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: darkOnSurface),
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: darkOnSurface,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkSurfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkSurfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryContainer, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryContainer,
          foregroundColor: onPrimaryContainer,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
