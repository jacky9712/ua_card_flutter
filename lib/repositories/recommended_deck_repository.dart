import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/ua_card.dart';

abstract class RecommendedDeckRepository {
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks();
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId);
}

class SupabaseRecommendedDeckRepository implements RecommendedDeckRepository {
  final _supabase = Supabase.instance.client;

  int _extractPrice(dynamic cardJson) {
    if (cardJson == null || cardJson['latest_prices'] == null) return 0;
    final lp = cardJson['latest_prices'];
    if (lp is List && lp.isNotEmpty) {
      return ((lp[0]['price_jpy'] ?? 0) as num).toInt();
    } else if (lp is Map) {
      return ((lp['price_jpy'] ?? 0) as num).toInt();
    }
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks() async {
    final response = await _supabase
        .from('recommended_decks')
        .select(
          '*, series(name_zh, series_code), recommended_deck_cards(quantity, cards(image_url, color, latest_prices(price_jpy)))',
        )
        // "Tier1" < "Tier1.5" < "Tier2" ... < "Tier6" 剛好是文字順序，可以直接排序；
        // 沒有 tier 的（例如熱門度來源）會排在最後，改用 win_rate 排序。
        .order('tier', ascending: true, nullsFirst: false)
        .order('win_rate', ascending: false)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];
    for (final row in (response as List)) {
      final map = Map<String, dynamic>.from(row);
      final List<dynamic> deckCards = map['recommended_deck_cards'] ?? [];

      int totalCount = 0;
      int totalPrice = 0;
      // 目前 recommended_decks.cover_card_url 種子資料都是空的，
      // 改成用牌組裡單價最高的那張卡當代表卡封面。
      String? coverImageUrl;
      int coverPrice = -1;
      // 牌組本身沒有獨立的顏色欄位，從內含的卡片顏色反推（可能雙色），
      // 給畫面的顏色篩選器用，用法跟複製到組牌編輯器時的顏色偵測一致。
      final Set<String> colors = {};
      for (final dc in deckCards) {
        final qty = (dc['quantity'] ?? 0) as int;
        final int price = _extractPrice(dc['cards']);
        totalCount += qty;
        totalPrice += price * qty;

        final String? imageUrl = dc['cards']?['image_url'];
        if (imageUrl != null && imageUrl.isNotEmpty && price > coverPrice) {
          coverImageUrl = imageUrl;
          coverPrice = price;
        }

        final String? color = dc['cards']?['color'];
        if (color != null && color.isNotEmpty) colors.add(color.toUpperCase());
      }

      map['total_card_count'] = totalCount;
      map['total_price'] = totalPrice;
      map['cover_image_url'] = coverImageUrl;
      map['colors'] = colors.toList();
      map.remove('recommended_deck_cards');
      result.add(map);
    }
    return result;
  }

  @override
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId) async {
    final response = await _supabase
        .from('recommended_deck_cards')
        .select('quantity, cards(*, latest_prices(price_jpy))')
        .eq('recommended_deck_id', deckId);

    final List<UACard> expandedCards = [];
    for (var item in (response as List)) {
      final card = UACard.fromJson(item['cards']);
      final int qty = item['quantity'];
      for (int i = 0; i < qty; i++) {
        expandedCards.add(card);
      }
    }
    return expandedCards;
  }
}
