import 'dart:collection';

import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/card_columns.dart';

/// 把 select 字串拆成資料列的 key（embed `latest_prices(price_jpy)` 對應 `latest_prices`）。
List<String> selectedColumns() => cardSelectColumns
    .split(', ')
    .map((c) => c == 'latest_prices(price_jpy)' ? 'latest_prices' : c)
    .toList();

final Map<String, dynamic> sample = {
  'id': 101,
  'series_id': 7,
  'card_number': 'UA01BT/CGH-1-001',
  'name': 'テスト',
  'color': 'RED',
  'image_url': 'https://example.com/a.png',
  'bp': 3500,
  'ap_cost': 2,
  'energy_req': 3,
  'effect_text': '効果',
  'trigger_text': 'トリガー',
  'latest_prices': null,
};

/// 只含常數裡欄位的資料列。
Map<String, dynamic> rowFromColumns(dynamic latestPrices) {
  final values = {...sample, 'latest_prices': latestPrices};
  return {for (final c in selectedColumns()) c: values[c]};
}

/// fromJson 有讀、但刻意不抓的欄位（model 以外沒人用，沒抓到就用預設值）。
const Set<String> intentionallyUnfetched = {
  'rarity', 'is_parallel', 'star_count', 'has_signature', 'tags', 'energy_generated', 'card_type',
};

/// 記下 fromJson 讀了哪些 key 的 Map，讀到的值一律是 null。
class _KeyRecordingMap extends MapBase<String, dynamic> {
  final Set<String> readKeys = {};

  @override
  dynamic operator [](Object? key) {
    readKeys.add(key as String);
    return null;
  }

  @override
  void operator []=(String key, dynamic value) {}
  @override
  void clear() {}
  @override
  Iterable<String> get keys => const [];
  @override
  dynamic remove(Object? key) => null;
}

void main() {
  group('cardSelectColumns', () {
    test('常數欄位與 fixture 一致', () {
      expect(selectedColumns().toSet(), sample.keys.toSet());
      expect(selectedColumns().length, 12);
    });

    test('fromJson 讀的每個 key 不是在常數裡，就是列在刻意不抓的清單', () {
      // UACard.fromJson 新讀一個欄位、卻忘了加進 cardSelectColumns 時，這裡會失敗。
      final recorder = _KeyRecordingMap();
      UACard.fromJson(recorder);
      expect(recorder.readKeys.difference(intentionallyUnfetched), selectedColumns().toSet());
      expect(intentionallyUnfetched.intersection(selectedColumns().toSet()), isEmpty);
    });

    test('latest_prices 為 List 時每個欄位都正確解析', () {
      final card = UACard.fromJson(rowFromColumns([
        {'price_jpy': 450},
      ]));
      expect(card.id, 101);
      expect(card.seriesId, 7);
      expect(card.cardNumber, 'UA01BT/CGH-1-001');
      expect(card.name, 'テスト');
      expect(card.color, 'RED');
      expect(card.imageUrl, 'https://example.com/a.png');
      expect(card.bp, 3500);
      expect(card.apCost, 2);
      expect(card.energyReq, 3);
      expect(card.effectText, '効果');
      expect(card.triggerText, 'トリガー');
      expect(card.price, 450);
    });

    test('latest_prices 為 Map 時價格正確解析', () {
      final card = UACard.fromJson(rowFromColumns({'price_jpy': 980}));
      expect(card.price, 980);
      expect(card.cardNumber, 'UA01BT/CGH-1-001');
    });

    test('未抓的欄位維持預設值', () {
      final card = UACard.fromJson(rowFromColumns([
        {'price_jpy': 450},
      ]));
      expect(card.rarity, isNull);
      expect(card.isParallel, false);
      expect(card.starCount, 0);
      expect(card.hasSignature, false);
      expect(card.tags, isNull);
      expect(card.energyGenerated, 0);
      expect(card.cardType, isNull);
    });
  });
}
