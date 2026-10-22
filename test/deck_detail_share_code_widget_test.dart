import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/main.dart';
import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/deck_share_code_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/screens/deck_detail_screen.dart';

class _FakeDeckShareCodeRepository implements DeckShareCodeRepository {
  String? lastDeckString;
  bool fail = false;

  @override
  Future<DeckShareCode> createShareCode(String deckString) async {
    lastDeckString = deckString;
    if (fail) throw Exception('rpc down');
    return DeckShareCode(code: '012345', expiresAt: DateTime(2026, 10, 23, 15, 30));
  }
}

void main() {
  late _FakeDeckShareCodeRepository fake;

  // 不帶 imageUrl，且直接開在 QR 分頁，不會建出 CachedNetworkImage。
  final cards = [
    UACard(id: 1, cardNumber: 'UA01BT-001'),
    UACard(id: 1, cardNumber: 'UA01BT-001'),
    UACard(id: 2, cardNumber: 'UA01BT-001', isParallel: true),
    UACard(id: 3, cardNumber: 'UA01BT-002'),
  ];

  setUp(() {
    fake = _FakeDeckShareCodeRepository();
  });

  Widget wrap() {
    return ProviderScope(
      overrides: [deckShareCodeRepositoryProvider.overrideWithValue(fake)],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: DeckDetailScreen(deckName: 'T', cardsInDeck: cards, initialTabIndex: 1),
      ),
    );
  }

  const generateKey = Key('deckShareCodeGenerate');
  const copyKey = Key('deckShareCodeCopy');

  testWidgets('產生代碼 → 顯示代碼與到期時間 → 複製寫入剪貼簿並跳 snackbar', (tester) async {
    String? clipboardText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        clipboardText = (call.arguments as Map)['text'] as String?;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.ensureVisible(find.byKey(generateKey));
    await tester.pump();
    await tester.tap(find.byKey(generateKey));
    await tester.pump();
    await tester.pump();

    // 同卡號一般版 2 張 + 平行版 1 張要加總成 3。
    expect(fake.lastDeckString, 'UA_DECK|UA01BT-001:3,UA01BT-002:1');
    expect(find.text('012345'), findsOneWidget);
    expect(find.text('2026/10/23 15:30 前有效'), findsOneWidget);

    await tester.ensureVisible(find.byKey(copyKey));
    await tester.pump();
    await tester.tap(find.byKey(copyKey));
    await tester.pump();
    await tester.pump();

    expect(clipboardText, '012345');
    expect(find.text('已複製分享代碼'), findsOneWidget);
  });

  testWidgets('RPC 失敗顯示錯誤訊息且不崩潰', (tester) async {
    fake.fail = true;

    await tester.pumpWidget(wrap());
    await tester.pump();
    await tester.ensureVisible(find.byKey(generateKey));
    await tester.pump();
    await tester.tap(find.byKey(generateKey));
    await tester.pump();
    await tester.pump();

    expect(find.textContaining('產生分享代碼失敗'), findsOneWidget);
    expect(find.byKey(const Key('deckShareCodeText')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
