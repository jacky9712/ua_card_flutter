import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ua_card.dart';

/// 「我的牌組」雲端牌組清單與打開過的牌組卡表的本機快取，離線時顯示上次同步的結果。
///
/// 以使用者 id 區分，避免換帳號看到別人的牌組。
/// load 遇到沒有快取、快取損壞或讀不到時回傳 `null`，絕不丟例外；save 也絕不丟例外。
abstract class MyDeckCacheStore {
  Future<List<Map<String, dynamic>>?> loadDecks(String userId);
  Future<void> saveDecks(String userId, List<Map<String, dynamic>> decks);
  Future<List<UACard>?> loadDeckCards(String userId, int deckId);
  Future<void> saveDeckCards(String userId, int deckId, List<UACard> cards);
}

class SharedPrefsMyDeckCacheStore implements MyDeckCacheStore {
  static String _decksKey(String userId) => 'my_decks_cache_v1_$userId';
  static String _deckCardsKey(String userId, int deckId) => 'my_deck_cards_cache_v1_${userId}_$deckId';

  @override
  Future<List<Map<String, dynamic>>?> loadDecks(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_decksKey(userId));
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! List) return null;
      // 雲端牌組刪光也是有效結果：空陣列照樣回 []，不當成沒快取。
      // 畫面用 `final int deckId = deck['id']` 讀 id，任一筆不是 int 就整份當成沒快取。
      for (final e in decoded) {
        if (e is! Map || e['id'] is! int) return null;
      }
      return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      // 用不帶型別的 catch：任何讀取或解析錯誤都當成沒快取。
      debugPrint('讀取我的牌組快取失敗: $e');
      return null;
    }
  }

  @override
  Future<void> saveDecks(String userId, List<Map<String, dynamic>> decks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_decksKey(userId), json.encode(decks));
    } catch (e) {
      // json.encode 遇到不可編碼的值丟的例外也在這裡吞掉。
      debugPrint('寫入我的牌組快取失敗: $e');
    }
  }

  @override
  Future<List<UACard>?> loadDeckCards(String userId, int deckId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_deckCardsKey(userId, deckId));
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! List || decoded.isEmpty) return null;
      return decoded.map((e) => UACard.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      // 用不帶型別的 catch：fromJson 遇到欄位型別不對會丟 TypeError，也要當成沒快取。
      debugPrint('讀取我的牌組卡表快取失敗: $e');
      return null;
    }
  }

  @override
  Future<void> saveDeckCards(String userId, int deckId, List<UACard> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deckCardsKey(userId, deckId), json.encode(cards.map((c) => c.toJson()).toList()));
    } catch (e) {
      debugPrint('寫入我的牌組卡表快取失敗: $e');
    }
  }
}
