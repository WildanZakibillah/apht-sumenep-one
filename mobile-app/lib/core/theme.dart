import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors from previous Login Screen
  static const Color primaryBlue = Color(0xFF1E3A8A); // Tailwind blue-900
  static const Color secondaryBlue = Color(0xFF3B82F6); // Tailwind blue-500
  static const Color backgroundColor = Color(0xFFF3F4F6); // Tailwind gray-100
  static const Color textDark = Color(0xFF1E293B); // Slate-800
  static const Color textLight = Colors.white;

  // State
  static final ValueNotifier<bool> isDarkMode = ValueNotifier<bool>(false);

  static void toggleTheme(BuildContext context) {
    isDarkMode.value = !isDarkMode.value;
    Element? rootElement;
    context.visitAncestorElements((element) {
      rootElement = element;
      return true;
    });
    void rebuild(Element el) {
      el.markNeedsBuild();
      el.visitChildren(rebuild);
    }
    if (rootElement != null) {
      rebuild(rootElement!);
    }
  }

  // New Colors for Home Screen based on Tailwind Config
  static Color get surface => isDarkMode.value ? const Color(0xFF09090B) : const Color(0xFFFAF8FF);
  static Color get onSurface => isDarkMode.value ? const Color(0xFFFAFAFA) : const Color(0xFF191B23);
  static Color get primaryContainer => isDarkMode.value ? const Color(0xFF1D4ED8) : const Color(0xFF2563EB);
  static Color get onPrimaryContainer => isDarkMode.value ? const Color(0xFFEFF6FF) : const Color(0xFFEEEFFF);
  static Color get primary => isDarkMode.value ? const Color(0xFF3B82F6) : const Color(0xFF004AC6);
  static Color get primaryFixed => isDarkMode.value ? const Color(0xFF1E3A8A) : const Color(0xFFDBE1FF);
  static Color get onPrimaryFixed => isDarkMode.value ? const Color(0xFFDBEAFE) : const Color(0xFF00174B);
  static Color get primaryFixedDim => isDarkMode.value ? const Color(0xFF1E40AF) : const Color(0xFFB4C5FF);
  static Color get onSurfaceVariant => isDarkMode.value ? const Color(0xFFA1A1AA) : const Color(0xFF434655);
  static Color get surfaceContainerLow => isDarkMode.value ? const Color(0xFF18181B) : const Color(0xFFF3F3FE);
  static Color get surfaceContainerLowest => isDarkMode.value ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  static Color get surfaceContainer => isDarkMode.value ? const Color(0xFF27272A) : const Color(0xFFEDEDF9);
  static Color get surfaceContainerHigh => isDarkMode.value ? const Color(0xFF3F3F46) : const Color(0xFFE7E7F3);
  static Color get surfaceVariant => isDarkMode.value ? const Color(0xFF27272A) : const Color(0xFFE1E2ED);
  static Color get outlineVariant => isDarkMode.value ? const Color(0xFF3F3F46) : const Color(0xFFC3C6D7);
  static Color get outline => isDarkMode.value ? const Color(0xFF52525B) : const Color(0xFF737686);
  
  static Color get secondaryContainer => isDarkMode.value ? const Color(0xFF065F46) : const Color(0xFF6CF8BB);
  static Color get onSecondaryContainer => isDarkMode.value ? const Color(0xFFD1FAE5) : const Color(0xFF00714D);
  static Color get secondaryFixed => isDarkMode.value ? const Color(0xFF047857) : const Color(0xFF6FFBBE);
  static Color get onSecondaryFixed => isDarkMode.value ? const Color(0xFFECFDF5) : const Color(0xFF002113);
  static Color get secondary => isDarkMode.value ? const Color(0xFF10B981) : const Color(0xFF006C49);
  
  static Color get tertiaryContainer => isDarkMode.value ? const Color(0xFF78350F) : const Color(0xFF996100);
  static Color get onTertiaryContainer => isDarkMode.value ? const Color(0xFFFEF3C7) : const Color(0xFFFFEEDD);
  static Color get tertiaryFixed => isDarkMode.value ? const Color(0xFF92400E) : const Color(0xFFFFDDB8);
  static Color get tertiaryFixedDim => isDarkMode.value ? const Color(0xFFB45309) : const Color(0xFFFFB95F);
  static Color get onTertiaryFixed => isDarkMode.value ? const Color(0xFFFFFBEB) : const Color(0xFF2A1700);
  static Color get tertiary => isDarkMode.value ? const Color(0xFFF59E0B) : const Color(0xFF784B00);
  
  static Color get errorContainer => isDarkMode.value ? const Color(0xFF7F1D1D) : const Color(0xFFFFDAD6);
  static Color get onErrorContainer => isDarkMode.value ? const Color(0xFFFEE2E2) : const Color(0xFF93000A);
  static Color get error => isDarkMode.value ? const Color(0xFFEF4444) : const Color(0xFFBA1A1A);
  
  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryBlue, secondaryBlue],
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: secondaryBlue,
        surface: surface,
        onSurface: onSurface,
        primaryContainer: primaryContainer,
        onPrimaryContainer: onPrimaryContainer,
        surfaceContainerLow: surfaceContainerLow,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      scaffoldBackgroundColor: surface,
    );
  }
}
