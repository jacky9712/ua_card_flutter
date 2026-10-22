import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/my_deck_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const decksKey = 'my_decks_cache_v1_userA';
  const cardsKey = 'my_deck_cards_cache_v1_userA_5';

  test('存了再讀，牌組欄位都拿得回來', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsMyDeckCacheStore();

    await store.saveDecks('userA', [
      {
        'id': 10,
        'user_id': 'userA',
        'name': '雲端牌組',
        'series_id': 3,
        'cover_card_url': null,
        'created_at': '2026-10-01T12:00:00Z',
        'series': {'name_zh': '咒術', 'series_code': 'UA01'},
        'total_price': 500,
      },
    ]);

    final decks = await store.loadDecks('userA');
    expect(decks, isNotNull);
    expect(decks!.length, 1);
    final deck = decks.single;
    expect(deck['id'], 10);
    expect(deck['name'], '雲端牌組');
    expect(deck['series_id'], 3);
    expect((deck['series'] as Map)['series_code'], 'UA01');
    expect(deck['total_price'], 500);
    expect(deck['created_at'], '2026-10-01T12:00:00Z');
  });

  test('不同帳號互不看見對方的快取', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsMyDeckCacheStore();

    await store.saveDecks('userA', [
      {'id': 10, 'name': 'A 的牌組'},
    ]);

    expect(await store.loadDecks('userB'), isNull);
    expect(await store.loadDecks('userA'), isNotNull);
  });

  test('沒有快取回 null', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SharedPrefsMyDeckCacheStore().loadDecks('userA'), isNull);
  });

  test('不是 JSON 回 null', () async {
    SharedPreferences.setMockInitialValues({decksKey: 'not json'});
    expect(await SharedPrefsMyDeckCacheStore().loadDecks('userA'), isNull);
  });

  test('不是陣列回 null', () async {
    SharedPreferences.setMockInitialValues({decksKey: '{"a":1}'});
    expect(await SharedPrefsMyDeckCacheStore().loadDecks('userA'), isNull);
  });

  test('id 不是 int 回 null', () async {
    SharedPreferences.setMockInitialValues({decksKey: '[{"id":"x"}]'});
    expect(await SharedPrefsMyDeckCacheStore().loadDecks('userA'), isNull);
  });

  test('空陣列是有效快取，回 [] 而不是 null', () async {
    SharedPreferences.setMockInitialValues({decksKey: '[]'});
    final decks = await SharedPrefsMyDeckCacheStore().loadDecks('userA');
    expect(decks, isNotNull);
    expect(decks, isEmpty);
  });

  test('卡表存了再讀，價格與系列拿得回來；其他牌組或帳號讀不到', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsMyDeckCacheStore();
    final card = UACard(id: 1, cardNumber: 'UA01BT-001', name: 'a', price: 300, seriesId: 2);

    await store.saveDeckCards('userA', 5, [card, card]);

    final cards = await store.loadDeckCards('userA', 5);
    expect(cards, isNotNull);
    expect(cards!.length, 2);
    expect(cards.first.price, 300);
    expect(cards.first.seriesId, 2);
    expect(await store.loadDeckCards('userA', 6), isNull);
    expect(await store.loadDeckCards('userB', 5), isNull);
  });

  test('卡表快取損壞回 null', () async {
    SharedPreferences.setMockInitialValues({cardsKey: 'not json'});
    expect(await SharedPrefsMyDeckCacheStore().loadDeckCards('userA', 5), isNull);
  });
}
