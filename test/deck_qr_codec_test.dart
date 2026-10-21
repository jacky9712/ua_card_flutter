import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/utils/deck_qr_codec.dart';

void main() {
  group('DeckQrCodec.encode', () {
    test('輸出 UA_DECK|卡號:張數 格式，保留順序', () {
      expect(DeckQrCodec.encode({'A-1': 3, 'B-2': 1}), 'UA_DECK|A-1:3,B-2:1');
    });

    test('encode 後 decode 可以還原', () {
      final counts = {'UA01BT-001': 4, 'UA01BT-002': 2};
      expect(DeckQrCodec.decode(DeckQrCodec.encode(counts)), counts);
    });
  });

  group('DeckQrCodec.decode', () {
    test('缺少 UA_DECK| 前綴回傳 null', () {
      expect(DeckQrCodec.decode('UA01BT-001:4'), isNull);
      expect(DeckQrCodec.decode('UA_PLAYER|x'), isNull);
    });

    test('超過 4 張夾到 4', () {
      expect(DeckQrCodec.decode('UA_DECK|UA01BT-001:99'), {'UA01BT-001': 4});
    });

    test('0、負數、非數字的 pair 被丟掉', () {
      expect(
        DeckQrCodec.decode('UA_DECK|UA01BT-001:0,UA01BT-002:x,UA01BT-003:-1,UA01BT-004:2'),
        {'UA01BT-004': 2},
      );
    });

    test('沒有任何有效 pair 回傳 null', () {
      expect(DeckQrCodec.decode('UA_DECK|UA01BT-001:0'), isNull);
      expect(DeckQrCodec.decode('UA_DECK|UA01BT-001:x'), isNull);
      expect(DeckQrCodec.decode('UA_DECK|'), isNull);
    });
  });

  group('DeckQrCodec.countsFromDeck', () {
    test('cards 裡找不到的 cardId 直接跳過，不丟例外', () {
      final counts = DeckQrCodec.countsFromDeck({1: 2, 99: 3}, [UACard(id: 1, cardNumber: 'A-1')]);
      expect(counts, {'A-1': 2});
    });
  });
}
