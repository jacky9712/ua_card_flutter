import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/utils/deck_stats.dart';

UACard _energy(int? req) => UACard(cardNumber: 'E', energyReq: req);
UACard _trigger(String? text) => UACard(cardNumber: 'T', triggerText: text);
UACard _color(String? color) => UACard(cardNumber: 'C', color: color);

void main() {
  group('DeckStats.energyDistribution', () {
    test('空清單回傳 0~6 全 0', () {
      expect(DeckStats.energyDistribution(const []),
          {0: 0, 1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0});
    });

    test('energyReq 為 null 計入 0', () {
      expect(DeckStats.energyDistribution([_energy(null)])[0], 1);
    });

    test('energyReq 6 與 9 都計入 6', () {
      expect(DeckStats.energyDistribution([_energy(6), _energy(9)])[6], 2);
    });

    test('一般值計入對應格，總和等於卡數', () {
      final cards = [_energy(1), _energy(3), _energy(3), _energy(5), _energy(0)];
      final dist = DeckStats.energyDistribution(cards);
      expect(dist[1], 1);
      expect(dist[3], 2);
      expect(dist[5], 1);
      expect(dist[0], 1);
      expect(dist.values.fold<int>(0, (a, b) => a + b), cards.length);
    });
  });

  group('DeckStats.triggerDistribution', () {
    const keys = [
      'SPECIAL',
      'COLOR',
      'FINAL',
      'DRAW',
      'GET',
      'ACTIVE',
      'RAID',
      'OTHER',
      'NONE',
    ];

    test('空清單 9 個 key 全 0', () {
      expect(DeckStats.triggerDistribution(const []),
          {for (final k in keys) k: 0});
    });

    test('null、空字串、- 歸 NONE', () {
      final dist = DeckStats.triggerDistribution(
          [_trigger(null), _trigger(''), _trigger('-')]);
      expect(dist['NONE'], 3);
    });

    for (final c in const [
      ['カラー', 'COLOR'],
      ['レイド', 'RAID'],
      ['スペシャル', 'SPECIAL'],
      ['アクティブ', 'ACTIVE'],
      ['ゲット', 'GET'],
      ['ドロー', 'DRAW'],
      ['ファイナル', 'FINAL'],
      ['xyz', 'OTHER'],
      ['レストにする…アクティブにならない', 'COLOR'],
    ]) {
      test('${c[0]} → ${c[1]}', () {
        final dist = DeckStats.triggerDistribution([_trigger(c[0])]);
        expect(dist[c[1]], 1);
        expect(dist.values.fold<int>(0, (a, b) => a + b), 1);
      });
    }
  });

  group('DeckStats.colorCounts', () {
    test('空清單回傳空 Map', () {
      expect(DeckStats.colorCounts(const []), isEmpty);
    });

    test('red 與 RED 合併成 RED', () {
      expect(DeckStats.colorCounts([_color('red'), _color('RED')]), {'RED': 2});
    });

    test('null 歸 UNKNOWN', () {
      expect(DeckStats.colorCounts([_color(null)]), {'UNKNOWN': 1});
    });

    test('依 colorOrder 排序，其他排在後面', () {
      final counts =
          DeckStats.colorCounts([_color('PURPLE'), _color('RED'), _color(null)]);
      expect(counts.keys.toList(), ['RED', 'PURPLE', 'UNKNOWN']);
    });
  });
}
