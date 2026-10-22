import 'package:flutter/material.dart';

// 卡牌遊戲風色票：深色底 + 金色點綴
class AppColors {
  static const background = Color(0xFF141419);
  static const surface = Color(0xFF1E1E24);
  static const surfaceHigh = Color(0xFF2C2C35);
  static const gold = Color(0xFFFFD700);
  static const amber = Color(0xFFFFB300);

  // 卡片顏色（卡片圖鑑 / 組牌 / 推薦牌組共用）
  static const cardRed = Color(0xFFE53935);
  static const cardBlue = Color(0xFF1E88E5);
  static const cardGreen = Color(0xFF43A047);
  static const cardYellow = Color(0xFFFFB300);
  static const cardPurple = Color(0xFF8E24AA);
  static const cardPurpleLight = Color(0xFFCE93D8); // 能源分布長條漸層的淺色端
  static const cardUnknown = Color(0xFF757575);

  // 推薦牌組 Tier 分級
  static const tier1 = Color(0xFFE53935);
  static const tier2 = Color(0xFFFF9800);
  static const tier3 = Color(0xFF1E88E5);

  // 對戰環境排行榜 2、3 名（第 1 名用 gold）
  static const rankSilver = Color(0xFFC0C0C0);
  static const rankBronze = Color(0xFFCD7F32);

  // 頭像 / 圖示底色（20% 透明的 amber）
  static const amberTint = Color(0x33FFC107);

  // 卡價文字
  static const priceText = Color(0xFFFFE082);

  // 主要行動按鈕（儲存牌組）
  static const actionRed = Color(0xFFE53935);

  /// 卡片顏色字串（RED/BLUE/GREEN/YELLOW/PURPLE，不分大小寫）→ 色碼；
  /// null 或不認得的字串回傳 [cardUnknown]。
  static Color cardColor(String? color) => switch (color?.toUpperCase()) {
        'RED' => cardRed,
        'BLUE' => cardBlue,
        'GREEN' => cardGreen,
        'YELLOW' => cardYellow,
        'PURPLE' => cardPurple,
        _ => cardUnknown,
      };
}

ThemeData buildTcgTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.gold,
    brightness: Brightness.dark,
  ).copyWith(
    primary: AppColors.gold,
    onPrimary: Colors.black,
    secondary: AppColors.amber,
    onSecondary: Colors.black,
    surface: AppColors.surface,
    onSurface: Colors.white,
    surfaceContainerHighest: AppColors.surfaceHigh,
    outline: AppColors.surfaceHigh,
    outlineVariant: AppColors.surfaceHigh,
  );

  final rounded12 = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.surfaceHigh,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.surfaceHigh),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.surfaceHigh)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.surfaceHigh)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.gold, width: 1.5)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: rounded12,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.gold,
        foregroundColor: Colors.black,
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
        shape: rounded12,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.gold),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.gold,
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.6)),
        shape: rounded12,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.gold,
      foregroundColor: Colors.black,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.gold.withValues(alpha: 0.35)),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: Colors.white),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.gold,
      unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
      indicatorColor: AppColors.gold,
    ),
  );
}
