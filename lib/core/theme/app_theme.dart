import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'theme_types.dart';

class AppTheme {
  // ==================== COLORS ====================
  // LEGACY / FREE THEME CONSTANTS (Kept for backward compatibility)
  static const Color primaryBlue = Color(0xFF3B82F6); // Blue 500
  static const Color primaryDark = Color(0xFF1D4ED8); // Blue 700
  static const Color primaryLight = Color(0xFF60A5FA); // Blue 400

  static const Color successGreen = Color(0xFF10B981); // Emerald 500
  static const Color secondaryTeal = Color(0xFF14B8A6); // Teal 500

  // Neutral Colors
  static const Color slate900 = Color(0xFF0F172A);

  static const Color slate800 = Color(0xFF1E293B); // Dark Blue/Grey
  static const Color slate700 = Color(0xFF334155); // Medium Dark
  static const Color slate200 = Color(0xFFE2E8F0); // Light Gray
  static const Color white = Color(0xFFFFFFFF); // White

  // Semantic Colors
  static const Color errorColor = Color(0xFFEF4444); // Red 500
  static const Color warningColor = Color(0xFFF59E0B); // Amber 500
  static const Color infoColor = Color(0xFF3B82F6); // Blue 500

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA); // Gray 50
  static const Color backgroundDark = Color(
    0xFF0B1120,
  ); // Rich Dark Blue/Black for depth
  static const Color cardLight = white;
  static const Color cardDark = Color(
    0xFF1E293B,
  ); // Slate 800 - Lighter than background

  // Text Colors
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate700;
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textLight = Color(0xFFF8FAFC); // Slate 50

  // ==================== SPACING ====================
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;

  // ==================== BORDER RADIUS ====================
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 24.0;

  // ==================== SHADOWS ====================
  static List<BoxShadow> shadowSm = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.04),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowPrimary = [
    BoxShadow(
      color: primaryBlue.withOpacity(0.2),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> shadowLg = [
    BoxShadow(
      color: Colors.black.withOpacity(0.15),
      blurRadius: 40,
      offset: const Offset(0, 20),
    ),
  ];

  // ==================== FACTORY METHODS ====================

  static ThemeData getTheme({
    required AppThemeType type,
    required Brightness brightness,
  }) {
    switch (type) {
      case AppThemeType.premium:
        return _getPremiumTheme();
      case AppThemeType.pro:
        return _getProTheme(brightness);
      case AppThemeType.free:
        return _getFreeTheme(brightness);
    }
  }

  // ==================== FREE THEME (Existing Baseline) ====================
  static ThemeData _getFreeTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Reuse existing constants
    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: primaryLight,
            onPrimary: slate900,
            secondary: secondaryTeal,
            onSecondary: white,
            surface: cardDark,
            onSurface: textLight,
            error: errorColor,
          )
        : const ColorScheme.light(
            primary: primaryBlue,
            onPrimary: white,
            secondary: secondaryTeal,
            onSecondary: white,
            surface: cardLight,
            onSurface: textPrimary,
            error: errorColor,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: isDark ? backgroundDark : backgroundLight,
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? backgroundDark : backgroundLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? white : textPrimary),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: isDark ? white : textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? slate700 : slate200),
        ),
        color: isDark ? cardDark : cardLight,
      ),
    );
  }

  // ==================== PRO THEME (High Density, Serious) ====================
  static ThemeData _getProTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // Pro uses a stricter, cooler palette
    final bg = isDark
        ? const Color(0xFF111827)
        : const Color(0xFFF3F4F6); // Gray 900 / Gray 100
    final surface = isDark ? const Color(0xFF1F2937) : white;
    final primary = isDark
        ? const Color(0xFF60A5FA)
        : const Color(0xFF2563EB); // Blue 600

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      visualDensity: VisualDensity.compact, // Higher density for pros
      colorScheme: isDark
          ? ColorScheme.dark(
              primary: primary,
              surface: surface,
              onSurface: white,
            )
          : ColorScheme.light(
              primary: primary,
              surface: surface,
              onSurface: const Color(0xFF111827),
            ),
      scaffoldBackgroundColor: bg,
      textTheme:
          GoogleFonts.jetBrainsMonoTextTheme(
            isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme,
          ).copyWith(
            displayLarge: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              letterSpacing: -1.0,
            ),
            titleMedium: GoogleFonts.inter(fontWeight: FontWeight.w600),
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        elevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        iconTheme: IconThemeData(
          color: isDark ? white : const Color(0xFF111827),
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 16, // Smaller, tighter title
          fontWeight: FontWeight.w700,
          color: isDark ? white : const Color(0xFF111827),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: const EdgeInsets.symmetric(
          horizontal: 0,
          vertical: 4,
        ), // Tighter lists
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            radiusSm,
          ), // Sharper corners for Pro
          side: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
        ),
        color: surface,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ), // Sharper
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ==================== PREMIUM THEME (Luxury, Dark/Glass) ====================
  // Premium forces a dark-ish aesthetic even in light mode, or has significant styling
  static ThemeData _getPremiumTheme() {
    const primary = Color(0xFF8B5CF6); // Violet
    const secondary = Color(0xFFEC4899); // Pink
    const bg = Color(0xFF0F172A); // Slate 900
    const surface = Color(0xFF1E293B); // Slate 800

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark, // Premium feels best in dark
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        surface: surface,
        onSurface: white,
        background: bg,
      ),
      scaffoldBackgroundColor: bg,
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.dark().textTheme,
      ), // Outfit is premium/modern
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent, // Glass effect preparatory
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: white,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withOpacity(0.6), // Translucent
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24), // Very soft corners
          side: BorderSide(color: white.withOpacity(0.1)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: white,
          elevation: 8,
          shadowColor: primary.withOpacity(0.5), // Glow effect
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // Light Theme
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      onPrimary: Colors.white,
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      surface: cardLight,
      onSurface: textPrimary,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundLight,
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
        bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
        bodySmall: TextStyle(fontSize: 12, color: textMuted),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textPrimary,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardLight,
      elevation: 0, // Ferntech styling usually flatter
      shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: slate200, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundLight,
      foregroundColor: textPrimary,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
    ),
  );

  // Dark Theme
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight, // Lighter blue for better contrast on dark
      onPrimary: slate900,
      secondary: secondaryTeal,
      onSecondary: Colors.white,
      surface: cardDark,
      onSurface: textLight,
      error: errorColor,
    ),
    scaffoldBackgroundColor: backgroundDark,
    textTheme: GoogleFonts.interTextTheme(
      const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textLight,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textLight,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: textLight,
        ),
        bodyLarge: TextStyle(fontSize: 16, color: textLight),
        bodyMedium: TextStyle(fontSize: 14, color: textLight),
        bodySmall: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: slate900, // Dark text on light button for contrast
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryLight,
        side: const BorderSide(color: primaryLight, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryLight,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: cardDark,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: slate700),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: slate700),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryLight, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorColor, width: 2),
      ),
      hintStyle: const TextStyle(color: Color(0xFF6B7280)),
      labelStyle: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: textLight,
      ),
    ),
    cardTheme: CardThemeData(
      color: cardDark,
      elevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: slate700, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundDark,
      foregroundColor: textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: textLight,
      ),
    ),
  );
}
