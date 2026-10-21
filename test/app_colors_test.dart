import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/theme/app_theme.dart';

void main() {
  group('AppColors.cardColor', () {
    test('五色各自對應', () {
      expect(AppColors.cardColor('RED'), const Color(0xFFE53935));
      expect(AppColors.cardColor('BLUE'), const Color(0xFF1E88E5));
      expect(AppColors.cardColor('GREEN'), const Color(0xFF43A047));
      expect(AppColors.cardColor('YELLOW'), const Color(0xFFFFB300));
      expect(AppColors.cardColor('PURPLE'), const Color(0xFF8E24AA));
    });

    test('不分大小寫', () {
      expect(AppColors.cardColor('red'), const Color(0xFFE53935));
      expect(AppColors.cardColor('Blue'), const Color(0xFF1E88E5));
      expect(AppColors.cardColor('gReEn'), const Color(0xFF43A047));
    });

    test('null 與未知字串回傳預設灰', () {
      expect(AppColors.cardColor(null), const Color(0xFF757575));
      expect(AppColors.cardColor(''), const Color(0xFF757575));
      expect(AppColors.cardColor('ORANGE'), const Color(0xFF757575));
    });
  });

  test('搬家後的色碼不變', () {
    expect(AppColors.tier1, const Color(0xFFE53935));
    expect(AppColors.tier2, const Color(0xFFFF9800));
    expect(AppColors.tier3, const Color(0xFF1E88E5));
    expect(AppColors.rankSilver, const Color(0xFFC0C0C0));
    expect(AppColors.rankBronze, const Color(0xFFCD7F32));
    expect(AppColors.amberTint, const Color(0x33FFC107));
    expect(AppColors.priceText, const Color(0xFFFFE082));
    expect(AppColors.actionRed, const Color(0xFFE53935));
  });
}
