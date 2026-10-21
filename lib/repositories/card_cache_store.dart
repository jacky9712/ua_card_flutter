import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ua_card.dart';

/// 組牌頁預設瀏覽第一頁卡片與系列清單的本機快取（stale-while-revalidate 用）。
///
/// load 遇到沒有快取、快取損壞或讀不到時回傳 `null`，絕不丟例外；save 也絕不丟例外。
abstract class CardCacheStore {
  Future<List<UACard>?> loadFirstPage();
  Future<List<String>?> loadSeries();
  Future<void> saveFirstPage(List<UACard> cards);
  Future<void> saveSeries(List<String> series);
}

class SharedPrefsCardCacheStore implements CardCacheStore {
  static const String _cardsKey = 'card_cache_first_page_v1';
  static const String _seriesKey = 'card_cache_series_v1';

  @override
  Future<List<UACard>?> loadFirstPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cardsKey);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! List || decoded.isEmpty) return null;
      return decoded.map((e) => UACard.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      // 用不帶型別的 catch：fromJson 遇到欄位型別不對會丟 TypeError，也要當成沒快取。
      debugPrint('讀取卡片快取失敗: $e');
      return null;
    }
  }

  @override
  Future<List<String>?> loadSeries() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_seriesKey);
      if (raw == null) return null;
      final decoded = json.decode(raw);
      if (decoded is! List || decoded.isEmpty) return null;
      return decoded.map((e) => e as String).toList();
    } catch (e) {
      debugPrint('讀取系列快取失敗: $e');
      return null;
    }
  }

  @override
  Future<void> saveFirstPage(List<UACard> cards) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_cardsKey, json.encode(cards.map((c) => c.toJson()).toList()));
    } catch (e) {
      debugPrint('寫入卡片快取失敗: $e');
    }
  }

  @override
  Future<void> saveSeries(List<String> series) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_seriesKey, json.encode(series));
    } catch (e) {
      debugPrint('寫入系列快取失敗: $e');
    }
  }
}
