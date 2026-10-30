import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ua_card_flutter/utils/deck_exporter.dart';

void main() {
  final imageBytes = Uint8List.fromList([1, 2, 3]);

  group('DeckExporter.deliverDeckImage', () {
    test('網頁：只下載 PNG，不呼叫分享', () async {
      final downloaded = <Uint8List>[];
      var shareCalls = 0;

      await DeckExporter.deliverDeckImage(
        imageBytes,
        shareText: 'text',
        shareSubject: 'subject',
        isWeb: true,
        download: (bytes) async => downloaded.add(bytes),
        share: (_, _, _) async => shareCalls++,
      );

      expect(downloaded, hasLength(1));
      expect(downloaded.single, same(imageBytes));
      expect(shareCalls, 0);
    });

    test('手機：開分享選單並帶原文字與主旨，不呼叫下載', () async {
      final shared = <(Uint8List, String, String)>[];
      var downloadCalls = 0;

      await DeckExporter.deliverDeckImage(
        imageBytes,
        shareText: 'text',
        shareSubject: 'subject',
        isWeb: false,
        download: (_) async => downloadCalls++,
        share: (bytes, text, subject) async =>
            shared.add((bytes, text, subject)),
      );

      expect(shared, hasLength(1));
      expect(shared.single.$1, same(imageBytes));
      expect(shared.single.$2, 'text');
      expect(shared.single.$3, 'subject');
      expect(downloadCalls, 0);
    });

    test('網頁：下載失敗時例外會往外傳，讓呼叫端顯示匯出失敗', () async {
      await expectLater(
        DeckExporter.deliverDeckImage(
          imageBytes,
          shareText: 'text',
          shareSubject: 'subject',
          isWeb: true,
          download: (_) async => throw StateError('download failed'),
          share: (_, _, _) async {},
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
