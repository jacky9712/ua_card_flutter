import '../models/ua_card.dart';
import '../utils/local_storage_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class DeckRepository {
  Future<List<Map<String, dynamic>>> fetchRemoteDecks(String userId);
  Future<List<Map<String, dynamic>>> fetchLocalDecks();
  Future<void> saveRemoteDeck({
    required String name,
    int? seriesId,
    String? coverCardUrl,
    required List<Map<String, dynamic>> cards,
  });
  Future<void> saveLocalDeck(Map<String, dynamic> deckData);
  Future<void> deleteRemoteDeck(int deckId);
  Future<void> deleteLocalDeck(int deckId);
  Future<List<UACard>> fetchRemoteDeckCards(int deckId);
}

class MixedDeckRepository implements DeckRepository {
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
  Future<List<Map<String, dynamic>>> fetchRemoteDecks(String userId) async {
    final response = await _supabase
        .from('decks')
        .select('*, series(name_zh, series_code), deck_cards(quantity, cards(latest_prices(price_jpy)))')
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    final List<Map<String, dynamic>> result = [];
    for (final row in (response as List)) {
      final map = Map<String, dynamic>.from(row);
      final List<dynamic> deckCards = map['deck_cards'] ?? [];

      int totalPrice = 0;
      for (final dc in deckCards) {
        final qty = (dc['quantity'] ?? 0) as int;
        totalPrice += _extractPrice(dc['cards']) * qty;
      }

      map['total_price'] = totalPrice;
      map.remove('deck_cards');
      result.add(map);
    }
    return result;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchLocalDecks() async {
    return await LocalStorageHelper.getLocalDecks();
  }

  @override
  Future<void> saveRemoteDeck({
    required String name,
    int? seriesId,
    String? coverCardUrl,
    required List<Map<String, dynamic>> cards,
  }) async {
    await _supabase.rpc('save_complete_deck', params: {
      'p_name': name,
      'p_series_id': seriesId,
      'p_cover_card_url': coverCardUrl,
      'p_cards': cards,
    });
  }

  @override
  Future<void> saveLocalDeck(Map<String, dynamic> deckData) async {
    await LocalStorageHelper.saveDeckLocally(deckData);
  }

  @override
  Future<void> deleteRemoteDeck(int deckId) async {
    await _supabase.from('decks').delete().eq('id', deckId);
  }

  @override
  Future<void> deleteLocalDeck(int deckId) async {
    await LocalStorageHelper.deleteLocalDeck(deckId);
  }

  @override
  Future<List<UACard>> fetchRemoteDeckCards(int deckId) async {
    final response = await _supabase
        .from('deck_cards')
        .select('quantity, cards(*, latest_prices(price_jpy))')
        .eq('deck_id', deckId);
    
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
