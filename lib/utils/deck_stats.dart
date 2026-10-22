// lib/utils/deck_stats.dart
import '../models/ua_card.dart';

/// 牌組詳情頁與組牌頁共用的統計（純 Dart）。
/// 傳入依張數展開的卡片清單（同一張卡出現幾次就算幾張）。
class DeckStats {
  DeckStats._();

  static const List<String> colorOrder = [
    'RED',
    'BLUE',
    'GREEN',
    'YELLOW',
    'PURPLE',
  ];

  // 🧮 統計功能一：計算必要能源 分佈
  static Map<int, int> energyDistribution(Iterable<UACard> cards) {
    final Map<int, int> dist = {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0};
    for (var card in cards) {
      final req = card.energyReq ?? 0;
      if (req >= 6) {
        dist[6] = (dist[6] ?? 0) + 1;
      } else {
        dist[req] = (dist[req] ?? 0) + 1;
      }
    }
    return dist;
  }

  // 🧮 統計功能二：觸發分佈 (精準識別 UA 各顏色 Color Trigger)
  static Map<String, int> triggerDistribution(Iterable<UACard> cards) {
    final Map<String, int> dist = {
      'SPECIAL': 0,
      'COLOR': 0,
      'FINAL': 0,
      'DRAW': 0,
      'GET': 0,
      'ACTIVE': 0,
      'RAID': 0,
      'OTHER': 0,
      'NONE': 0,
    };
    for (var card in cards) {
      final text = card.triggerText?.trim() ?? '';

      if (text.isEmpty || text == '-') {
        dist['NONE'] = dist['NONE']! + 1;
        continue;
      }

      // 1. 優先判定 COLOR (使用您提供的精準描述)
      if (text.contains('カラー') ||
          text.contains('COLOR') ||
          text.contains('BP2500以下の相手') || // 紅色 Color
          text.contains('BP3500以下の相手') || // 藍色 Color
          (text.contains('レストにする') &&
              text.contains('アクティブにならない')) || // 黃色 Color
          (text.contains('2以下') &&
              text.contains('消費APが1') &&
              text.contains('登場させる'))) {
        // 綠/紫 Color
        dist['COLOR'] = dist['COLOR']! + 1;
      }
      // 2. 判定 RAID (截圖中的重要類別)
      else if (text.contains('レイド') || text.contains('RAID')) {
        dist['RAID'] = dist['RAID']! + 1;
      }
      // 3. 判定 SPECIAL (排除掉已認定的 Color)
      else if (text.contains('スペシャル') ||
          text.contains('SPECIAL') ||
          text.contains('退場させる')) {
        dist['SPECIAL'] = dist['SPECIAL']! + 1;
      }
      // 4. 其餘標準觸發
      else if (text.contains('アクティブ') || text.contains('ACTIVE')) {
        dist['ACTIVE'] = dist['ACTIVE']! + 1;
      } else if (text.contains('手札に加える') ||
          text.contains('ゲット') ||
          text.contains('GET')) {
        dist['GET'] = dist['GET']! + 1;
      } else if (text.contains('1枚引く') ||
          text.contains('ドロー') ||
          text.contains('DRAW')) {
        dist['DRAW'] = dist['DRAW']! + 1;
      } else if (text.contains('ファイナル') ||
          text.contains('FINAL') ||
          text.contains('自分のライフエリアに置く')) {
        dist['FINAL'] = dist['FINAL']! + 1;
      } else {
        dist['OTHER'] = dist['OTHER']! + 1;
      }
    }
    return dist;
  }

  /// 顏色 -> 張數。key 為大寫顏色，null/空字串歸 'UNKNOWN'；只含張數 > 0 的顏色，
  /// 先依 [colorOrder] 排序，其餘依第一次出現順序排在後面。
  static Map<String, int> colorCounts(Iterable<UACard> cards) {
    final Map<String, int> raw = {};
    for (final card in cards) {
      final c = card.color?.trim().toUpperCase() ?? '';
      final key = c.isEmpty ? 'UNKNOWN' : c;
      raw[key] = (raw[key] ?? 0) + 1;
    }
    final Map<String, int> ordered = {};
    for (final key in colorOrder) {
      if (raw.containsKey(key)) ordered[key] = raw[key]!;
    }
    for (final entry in raw.entries) {
      if (!ordered.containsKey(entry.key)) ordered[entry.key] = entry.value;
    }
    return ordered;
  }
}
