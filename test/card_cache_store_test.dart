import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/card_cache_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('UACard.toJson 再 fromJson 每個欄位都還原', () {
    final card = UACard(
      id: 7,
      seriesId: 3,
      cardNumber: 'UA01BT-001',
      name: '名字',
      rarity: 'SR',
      isParallel: true,
      starCount: 2,
      hasSignature: true,
      color: 'RED',
      imageUrl: 'https://example.com/a.png',
      cardType: 'CHARACTER',
      bp: 3000,
      apCost: 2,
      energyReq: 3,
      energyGenerated: 1,
      tags: ['a'],
      effectText: 'effect',
      triggerText: 'trigger',
      price: 450,
    );

    final back = UACard.fromJson(card.toJson());

    expect(back.id, 7);
    expect(back.seriesId, 3);
    expect(back.cardNumber, 'UA01BT-001');
    expect(back.name, '名字');
    expect(back.rarity, 'SR');
    expect(back.isParallel, isTrue);
    expect(back.starCount, 2);
    expect(back.hasSignature, isTrue);
    expect(back.color, 'RED');
    expect(back.imageUrl, 'https://example.com/a.png');
    expect(back.cardType, 'CHARACTER');
    expect(back.bp, 3000);
    expect(back.apCost, 2);
    expect(back.energyReq, 3);
    expect(back.energyGenerated, 1);
    expect(back.tags, ['a']);
    expect(back.effectText, 'effect');
    expect(back.triggerText, 'trigger');
    expect(back.price, 450);
  });

  test('存了再讀，卡片與系列清單都拿得回來', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsCardCacheStore();

    await store.saveFirstPage([
      UACard(id: 1, cardNumber: 'UA01BT-001', price: 100),
      UACard(id: 2, cardNumber: 'UA01BT-002'),
    ]);
    await store.saveSeries(['UA01', 'UA02']);

    final cards = await store.loadFirstPage();
    expect(cards!.map((c) => c.cardNumber), ['UA01BT-001', 'UA01BT-002']);
    expect(cards.map((c) => c.price), [100, null]);
    expect(await store.loadSeries(), ['UA01', 'UA02']);
  });

  test('沒有快取時回傳 null', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SharedPrefsCardCacheStore();

    expect(await store.loadFirstPage(), isNull);
    expect(await store.loadSeries(), isNull);
  });

  test('快取損壞時當成沒有快取，不丟例外', () async {
    SharedPreferences.setMockInitialValues({
      'card_cache_first_page_v1': 'not json',
      'card_cache_series_v1': '{"a":1}',
    });
    final store = SharedPrefsCardCacheStore();
    expect(await store.loadFirstPage(), isNull);
    expect(await store.loadSeries(), isNull);
  });

  test('欄位型別不對（fromJson 丟 TypeError）也當成沒有快取', () async {
    SharedPreferences.setMockInitialValues({'card_cache_first_page_v1': '[{"id":"x"}]'});
    expect(await SharedPrefsCardCacheStore().loadFirstPage(), isNull);
  });

  test('空陣列當成沒有快取', () async {
    SharedPreferences.setMockInitialValues({
      'card_cache_first_page_v1': '[]',
      'card_cache_series_v1': '[]',
    });
    final store = SharedPrefsCardCacheStore();
    expect(await store.loadFirstPage(), isNull);
    expect(await store.loadSeries(), isNull);
  });
}
