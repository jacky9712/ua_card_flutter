// lib/utils/deck_qr_codec.dart
import '../models/ua_card.dart';

/// 牌組 QR 字串 `UA_DECK|卡號:張數,...` 的編碼與解碼（純 Dart）。
class DeckQrCodec {
  DeckQrCodec._();

  static const String prefix = 'UA_DECK|';
  static const int maxCopiesPerCard = 4; // 與 DeckViewModel.updateCardQuantity 的上限一致

  /// cardNumber -> quantity 轉成 'UA_DECK|n1:q1,n2:q2'（保留 Map 的迭代順序）
  static String encode(Map<String, int> counts) =>
      '$prefix${counts.entries.map((e) => '${e.key}:${e.value}').join(',')}';

  /// 解析 QR 字串；前綴不對或沒有任何有效 pair 時回傳 null。
  /// 張數必須是正整數，超過 4 的夾到 4；0、負數、非數字的 pair 直接丟掉。
  static Map<String, int>? decode(String data) {
    if (!data.startsWith(prefix)) return null;
    final Map<String, int> result = {};
    for (final piece in data.substring(prefix.length).split(',')) {
      final parts = piece.split(':');
      if (parts.length != 2) continue;
      final number = parts[0].trim();
      if (number.isEmpty) continue;
      final qty = int.tryParse(parts[1].trim());
      if (qty == null || qty <= 0) continue;
      result[number] = qty > maxCopiesPerCard ? maxCopiesPerCard : qty;
    }
    return result.isEmpty ? null : result;
  }

  /// deckMap (cardId -> qty) 配上卡片清單，轉成 cardNumber -> qty；
  /// cards 裡找不到的 cardId 直接跳過，不丟例外。
  /// 同卡號不同版本（不同 id，如一般/平行/星/簽名）的張數會加總。
  static Map<String, int> countsFromDeck(Map<int, int> deckMap, Iterable<UACard> cards) {
    final byId = <int, UACard>{for (final c in cards) if (c.id != null) c.id!: c};
    final Map<String, int> result = {};
    deckMap.forEach((id, qty) {
      final c = byId[id];
      if (c != null) result[c.cardNumber] = (result[c.cardNumber] ?? 0) + qty;
    });
    return result;
  }

  /// deckMap (cardId -> qty) 配上卡片清單，直接編成 QR 字串。
  static String encodeDeck(Map<int, int> deckMap, Iterable<UACard> cards) =>
      encode(countsFromDeck(deckMap, cards));
}
