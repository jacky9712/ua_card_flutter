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

void main() {
  group('cardSelectColumns', () {
    test('常數欄位與 fixture 一致', () {
      expect(selectedColumns().toSet(), sample.keys.toSet());
      expect(selectedColumns().length, 12);
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
