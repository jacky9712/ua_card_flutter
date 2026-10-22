import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/utils/match_record_stats.dart';

void main() {
  group('resultFromMyPerspective', () {
    test('我是 player 時結果不變', () {
      for (final r in ['win', 'loss', 'draw']) {
        expect(resultFromMyPerspective({'player_id': 'me', 'result': r}, 'me'), r);
      }
    });

    test('我是 opponent 時 win/loss 對調，draw 不變', () {
      expect(resultFromMyPerspective({'player_id': 'other', 'opponent_id': 'me', 'result': 'win'}, 'me'), 'loss');
      expect(resultFromMyPerspective({'player_id': 'other', 'opponent_id': 'me', 'result': 'loss'}, 'me'), 'win');
      expect(resultFromMyPerspective({'player_id': 'other', 'opponent_id': 'me', 'result': 'draw'}, 'me'), 'draw');
    });
  });

  group('MatchStats.winRate', () {
    test('只有平手時為 0', () {
      expect(const MatchStats(draw: 3).winRate, 0);
    });

    test('平手不計入分母', () {
      expect(const MatchStats(win: 1, loss: 1, draw: 5).winRate, 50);
    });
  });

  group('matchStatsByDeck', () {
    test('只計我記的紀錄，未填牌組歸同一組，同名合併，場次多的在前', () {
      final records = <Map<String, dynamic>>[
        {'player_id': 'me', 'deck_name_snapshot': null, 'result': 'win'},
        {'player_id': 'me', 'deck_name_snapshot': 'A', 'result': 'win'},
        {'player_id': 'other', 'opponent_id': 'me', 'deck_name_snapshot': 'A', 'result': 'win'},
        {'player_id': 'me', 'deck_name_snapshot': 'B', 'result': 'loss'},
        {'player_id': 'me', 'deck_name_snapshot': 'B', 'result': 'win'},
        {'player_id': 'me', 'deck_name_snapshot': ' B ', 'result': 'draw'},
        {'player_id': 'me', 'deck_name_snapshot': '', 'result': 'loss'},
      ];

      final groups = matchStatsByDeck(records, 'me');

      expect(groups.map((g) => g.key).toList(), ['B', '', 'A']);
      final b = groups[0];
      expect(b.label, 'B');
      expect([b.stats.win, b.stats.loss, b.stats.draw], [1, 1, 1]);
      final unspecified = groups[1];
      expect(unspecified.label, isNull);
      expect([unspecified.stats.win, unspecified.stats.loss, unspecified.stats.draw], [1, 1, 0]);
      final a = groups[2];
      expect(a.label, 'A');
      expect([a.stats.win, a.stats.loss, a.stats.draw], [1, 0, 0]);
    });

    test('myUserId 為 null 時回空清單', () {
      expect(matchStatsByDeck([{'player_id': 'me', 'result': 'win'}], null), isEmpty);
    });
  });

  group('matchStatsByOpponent', () {
    test('帳號對手兩邊紀錄合併且結果反轉，文字名字合併，前綴避免撞名', () {
      final records = <Map<String, dynamic>>[
        {
          'player_id': 'me',
          'opponent_id': 'u1',
          'opponent_profile': {'display_name': '小華'},
          'result': 'win',
        },
        {
          'player_id': 'u1',
          'opponent_id': 'me',
          'player_profile': {'display_name': '小華'},
          'result': 'win', // 他贏了我 → 我敗
        },
        {'player_id': 'me', 'opponent_id': null, 'opponent_name_text': '阿明', 'result': 'loss'},
        {'player_id': 'me', 'opponent_id': null, 'opponent_name_text': ' 阿明 ', 'result': 'draw'},
        {'player_id': 'me', 'opponent_id': null, 'opponent_name_text': 'u1', 'result': 'win'},
        {
          'player_id': 'u2',
          'opponent_id': 'me',
          'player_profile': {'display_name': '小美'},
          'result': 'loss', // 他輸了 → 我勝
        },
      ];

      final groups = matchStatsByOpponent(records, 'me');
      final byKey = {for (final g in groups) g.key: g};

      expect(byKey.keys.toSet(), {'user:u1', 'name:阿明', 'name:u1', 'user:u2'});

      final u1 = byKey['user:u1']!;
      expect(u1.label, '小華');
      expect([u1.stats.win, u1.stats.loss, u1.stats.draw], [1, 1, 0]);

      final aming = byKey['name:阿明']!;
      expect(aming.label, '阿明');
      expect([aming.stats.win, aming.stats.loss, aming.stats.draw], [0, 1, 1]);

      final nameU1 = byKey['name:u1']!;
      expect(nameU1.stats.total, 1);

      final u2 = byKey['user:u2']!;
      expect(u2.label, '小美');
      expect([u2.stats.win, u2.stats.loss, u2.stats.draw], [1, 0, 0]);

      // 場次多的在前；同場次照第一次出現順序。
      expect(groups.map((g) => g.key).toList(), ['user:u1', 'name:阿明', 'name:u1', 'user:u2']);
    });

    test('沒有名字也沒有 profile 時 label 為 null', () {
      final groups = matchStatsByOpponent([
        {'player_id': 'me', 'opponent_id': null, 'opponent_name_text': null, 'result': 'win'},
        {'player_id': 'me', 'opponent_id': 'u3', 'result': 'win'},
      ], 'me');

      expect(groups.map((g) => g.key).toList(), ['name:', 'user:u3']);
      expect(groups.every((g) => g.label == null), isTrue);
    });

    test('myUserId 為 null 時回空清單', () {
      expect(matchStatsByOpponent([{'player_id': 'me', 'result': 'win'}], null), isEmpty);
    });
  });
}
