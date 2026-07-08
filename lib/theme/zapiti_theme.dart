import 'package:flutter/material.dart';

class ZapitiColors {
  static const tableGreen = Color(0xFF0F3B2E);
  static const tableGreenDark = Color(0xFF09271F);
  static const cardCream = Color(0xFFF6EEDB);
  static const wineRed = Color(0xFF7B1E22);
  static const oldGold = Color(0xFFC9A227);
  static const darkBrown = Color(0xFF2B1B12);
  static const wood = Color(0xFF6F4324);
  static const woodDark = Color(0xFF3E2416);
  static const softIvory = Color(0xFFFFFAEE);
}

class ZapitiTheme {
  const ZapitiTheme._();

  static ThemeData get theme {
    final scheme = ColorScheme.fromSeed(
      seedColor: ZapitiColors.wineRed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme.copyWith(
        primary: ZapitiColors.wineRed,
        secondary: ZapitiColors.oldGold,
        surface: ZapitiColors.softIvory,
        onSurface: ZapitiColors.darkBrown,
      ),
      scaffoldBackgroundColor: ZapitiColors.tableGreen,
      appBarTheme: const AppBarTheme(
        backgroundColor: ZapitiColors.tableGreenDark,
        foregroundColor: ZapitiColors.cardCream,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: ZapitiColors.softIvory,
        elevation: 4,
        shadowColor: Colors.black.withValues(alpha: 0.18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
