import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/main.dart';
import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/card_cache_store.dart';
import 'package:ua_card_flutter/repositories/card_repository.dart';
import 'package:ua_card_flutter/repositories/meta_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/screens/deck_builder_screen.dart';
import 'package:ua_card_flutter/viewModels/deck_view_model.dart';
import 'package:ua_card_flutter/widgets/deck_distribution_charts.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMetaRepository implements MetaRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchEnvironmentData() async => [];
}

// 空的快取：widget 測試不碰 SharedPreferences 平台通道。
class _EmptyCardCacheStore implements CardCacheStore {
  @override
  Future<List<UACard>?> loadFirstPage() async => null;

  @override
  Future<List<String>?> loadSeries() async => null;

  @override
  Future<void> saveFirstPage(List<UACard> cards) async {}

  @override
  Future<void> saveSeries(List<String> series) async {}
}

// browseResult 保持空：畫面停在「找不到卡片」，不會建出 CachedNetworkImage。
class _FakeCardRepository implements CardRepository {
  List<UACard> browseResult = const [];

  @override
  Future<List<String>> fetchSeriesList() async => [];

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    return browseResult;
  }

  @override
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeCardRepository repo;

  setUp(() {
    repo = _FakeCardRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      metaRepositoryProvider.overrideWithValue(_FakeMetaRepository()),
      cardRepositoryProvider.overrideWithValue(repo),
      cardCacheStoreProvider.overrideWithValue(_EmptyCardCacheStore()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Widget wrap(ProviderContainer container, Widget home) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: home,
      ),
    );
  }

  const summaryKey = Key('deckHealthSummary');
  const detailsKey = Key('deckHealthDetails');
  final red = UACard(id: 1, cardNumber: 'A-1', color: 'RED', energyReq: 2);
  final blue = UACard(id: 2, cardNumber: 'B-1', color: 'BLUE', energyReq: 0);

  Future<void> pumpBuilder(WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(wrap(container, const DeckBuilderScreen()));
    await tester.pump();
    await tester.pump();
  }

  testWidgets('空牌組：摘要正常顯示，展開也不拋例外', (tester) async {
    final container = makeContainer();
    await pumpBuilder(tester, container);

    expect(find.byKey(summaryKey), findsOneWidget);
    expect(find.text('尚未加入卡片'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(summaryKey));
    await tester.pump();

    expect(find.byKey(detailsKey), findsOneWidget);
    expect(find.text('成本分佈'), findsOneWidget);
    expect(find.text('觸發分佈'), findsOneWidget);
    expect(find.byType(EnergyDistributionChart), findsOneWidget);
    expect(find.byType(TriggerDistributionGrid), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('加減卡片時顏色張數與費用長條即時更新', (tester) async {
    final container = makeContainer();
    await pumpBuilder(tester, container);

    final notifier = container.read(deckViewModelProvider.notifier);
    notifier.updateCardQuantity(red, 1);
    notifier.updateCardQuantity(red, 1);
    notifier.updateCardQuantity(blue, 1);
    await tester.pump();

    String countOf(String color) =>
        tester.widget<Text>(find.byKey(Key('deckHealthColorCount_$color'))).data!;

    expect(countOf('RED'), '2');
    expect(countOf('BLUE'), '1');
    expect(find.text('尚未加入卡片'), findsNothing);
    expect(
      tester.getSize(find.byKey(const Key('deckHealthCostBar_2'))).height,
      greaterThan(tester.getSize(find.byKey(const Key('deckHealthCostBar_0'))).height),
    );

    notifier.updateCardQuantity(red, -1);
    notifier.updateCardQuantity(red, -1);
    await tester.pump();

    expect(find.byKey(const Key('deckHealthColorCount_RED')), findsNothing);
    expect(countOf('BLUE'), '1');
    expect(tester.takeException(), isNull);
  });

  testWidgets('點擊摘要展開，再點一次收合', (tester) async {
    final container = makeContainer();
    await pumpBuilder(tester, container);

    container.read(deckViewModelProvider.notifier).updateCardQuantity(red, 1);
    await tester.pump();

    await tester.tap(find.byKey(summaryKey));
    await tester.pump();
    expect(find.byKey(detailsKey), findsOneWidget);

    await tester.tap(find.byKey(summaryKey));
    await tester.pump();
    expect(find.byKey(detailsKey), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('展開區的圖表用主題文字色，和牌組詳情頁一致', (tester) async {
    final container = makeContainer();
    await pumpBuilder(tester, container);

    await tester.tap(find.byKey(summaryKey));
    await tester.pump();

    final themeText = Theme.of(tester.element(find.byKey(detailsKey))).textTheme.bodyLarge?.color;
    expect(themeText, isNot(Colors.white)); // 測試用的預設亮色主題，寫死白色會被抓到
    expect(tester.widget<EnergyDistributionChart>(find.byType(EnergyDistributionChart)).textColor, themeText);
    expect(tester.widget<TriggerDistributionGrid>(find.byType(TriggerDistributionGrid)).textColor, themeText);
  });
}
