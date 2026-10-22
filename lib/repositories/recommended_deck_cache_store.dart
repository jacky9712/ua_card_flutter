import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 推薦牌組清單（`RecommendedDeckRepository.fetchRecommendedDecks` 加工後的結果）的本機快取，
/// stale-while-revalidate 用。
///
/// load 遇到沒有快取、快取損壞或讀不到時回傳 `null`，絕不丟例外；save 也絕不丟例外。
abstract class RecommendedDeckCacheStore {
  Future<List<Map<String, dynamic>>?> loadDecks();
  Future<void> saveDecks(List<Map<String, dynamic>> decks);
}

class SharedPrefsRecommendedDeckCacheStore implements RecommendedDeckCacheStore {
  static const String _decksKey = 'recommended_decks_cache_v1';

  @override
  Future<List<Map<String, dynamic>>?> loadDecks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_decksKey);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! List || decoded.isEmpty) return null;
      // 畫面用 `final int deckId = deck['id']` 讀 id，任一筆不是 int 就整份當成沒快取。
      for (final e in decoded) {
        if (e is! Map || e['id'] is! int) return null;
      }
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      // 用不帶型別的 catch：任何讀取或解析錯誤都當成沒快取。
      debugPrint('讀取推薦牌組快取失敗: $e');
      return null;
    }
  }

  @override
  Future<void> saveDecks(List<Map<String, dynamic>> decks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_decksKey, json.encode(decks));
    } catch (e) {
      // json.encode 遇到不可編碼的值丟的例外也在這裡吞掉。
      debugPrint('寫入推薦牌組快取失敗: $e');
    }
  }
}
