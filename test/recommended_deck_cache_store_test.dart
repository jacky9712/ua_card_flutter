import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ua_card_flutter/repositories/recommended_deck_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const key = 'recommended_decks_cache_v1';

  test('存了再讀，牌組欄位都拿得回來', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsRecommendedDeckCacheStore();

    await store.saveDecks([
      {
        'id': 7,
        'name': 'Tier 1 紅',
        'series_id': 3,
        'series': {'name_zh': '咒術', 'series_code': 'UA01'},
        'tier': 'Tier1',
        'win_rate': 55.5,
        'total_card_count': 50,
        'total_price': 1200,
        'cover_image_url': null,
        'colors': ['RED', 'BLUE'],
      },
    ]);

    final decks = await store.loadDecks();
    expect(decks, hasLength(1));
    final deck = decks!.single;
    expect(deck['id'], 7);
    expect(deck['name'], 'Tier 1 紅');
    expect(deck['series']['series_code'], 'UA01');
    expect(deck['colors'], ['RED', 'BLUE']);
    expect(deck['total_price'], 1200);
    expect(deck['win_rate'], 55.5);
  });

  test('沒有快取時回傳 null', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await SharedPrefsRecommendedDeckCacheStore().loadDecks(), isNull);
  });

  test('快取損壞時當成沒有快取，不丟例外', () async {
    SharedPreferences.setMockInitialValues({key: 'not json'});
    expect(await SharedPrefsRecommendedDeckCacheStore().loadDecks(), isNull);
  });

  test('空陣列當成沒有快取', () async {
    SharedPreferences.setMockInitialValues({key: '[]'});
    expect(await SharedPrefsRecommendedDeckCacheStore().loadDecks(), isNull);
  });

  test('id 不是 int 時當成沒有快取', () async {
    SharedPreferences.setMockInitialValues({key: '[{"id":"x"}]'});
    expect(await SharedPrefsRecommendedDeckCacheStore().loadDecks(), isNull);
  });

  test('不是陣列時當成沒有快取', () async {
    SharedPreferences.setMockInitialValues({key: '{"a":1}'});
    expect(await SharedPrefsRecommendedDeckCacheStore().loadDecks(), isNull);
  });
}
