import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/utils/deck_stats.dart';

UACard _energy(int? req) => UACard(cardNumber: 'E', energyReq: req);
UACard _trigger(String? text) => UACard(cardNumber: 'T', triggerText: text);
UACard _color(String? color) => UACard(cardNumber: 'C', color: color);
UACard _num(String n, {int id = 0}) => UACard(id: id, cardNumber: n);

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

  group('DeckStats.overLimitCardNumbers', () {
    test('同卡號普通版 4 張 + 平行版 1 張 = 5 張時提醒', () {
      final normal = _num('UA01BT-001', id: 1);
      final parallel =
          UACard(id: 2, cardNumber: 'UA01BT-001', isParallel: true);
      final cards = [normal, normal, normal, normal, parallel];
      expect(DeckStats.overLimitCardNumbers(cards), {'UA01BT-001': 5});
    });

    test('普通版 3 張 + 星級版 1 張 = 剛好 4 張不提醒', () {
      final normal = _num('UA01BT-001', id: 1);
      final star = UACard(id: 3, cardNumber: 'UA01BT-001', starCount: 1);
      final cards = [normal, normal, normal, star];
      expect(DeckStats.overLimitCardNumbers(cards), isEmpty);
    });

    test('空清單回傳空 Map', () {
      expect(DeckStats.overLimitCardNumbers(const []), isEmpty);
    });
  });

  group('DeckStats.overLimitTriggers', () {
    List<UACard> times(String text, int n) =>
        [for (var i = 0; i < n; i++) _trigger(text)];

    test('Special 5 張時提醒', () {
      expect(DeckStats.overLimitTriggers(times('スペシャル', 5)), {'SPECIAL': 5});
    });

    test('Special 4 張 + Final 4 張不提醒', () {
      expect(
        DeckStats.overLimitTriggers(
            [...times('スペシャル', 4), ...times('ファイナル', 4)]),
        isEmpty,
      );
    });

    test('Final 5 張 + Special 4 張只提醒 Final', () {
      expect(
        DeckStats.overLimitTriggers(
            [...times('ファイナル', 5), ...times('スペシャル', 4)]),
        {'FINAL': 5},
      );
    });

    test('兩者都超過時依序 SPECIAL、FINAL', () {
      final result = DeckStats.overLimitTriggers(
          [...times('ファイナル', 5), ...times('スペシャル', 5)]);
      expect(result.keys.toList(), ['SPECIAL', 'FINAL']);
    });
  });

  group('DeckStats.openingHandHitProbability / zeroEnergyCount', () {
    test('50 張中 10 張 0 能，起手 7 張至少 1 張約 81.3%', () {
      expect(DeckStats.openingHandHitProbability(deckSize: 50, hits: 10),
          closeTo(0.8133, 0.0005));
    });

    test('牌組不到 7 張回傳 null', () {
      expect(DeckStats.openingHandHitProbability(deckSize: 6, hits: 3), isNull);
    });

    test('沒有 0 能卡時機率為 0', () {
      expect(DeckStats.openingHandHitProbability(deckSize: 7, hits: 0), 0.0);
    });

    test('非 0 能卡不到 7 張時機率為 1', () {
      expect(DeckStats.openingHandHitProbability(deckSize: 50, hits: 44), 1.0);
    });

    test('energyReq 為 null 視為 0 能', () {
      expect(
          DeckStats.zeroEnergyCount([_energy(null), _energy(0), _energy(1)]), 2);
    });
  });
}
