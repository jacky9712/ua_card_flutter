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
import 'package:ua_card_flutter/repositories/recommended_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_repository.dart';
import 'package:ua_card_flutter/screens/deck_builder_screen.dart';
import 'package:ua_card_flutter/screens/home_screen.dart';
import 'package:ua_card_flutter/utils/wide_web_layout.dart';

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
  Future<List<Map<String, dynamic>>> fetchEnvironmentData() async => [
        {'name_zh': '測試系列', 'share_rate': 12},
      ];
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

class _FakeRecommendedDeckRepository implements RecommendedDeckRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks() async => [];

  @override
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId) async => [];
}

class _EmptyRecommendedDeckCacheStore implements RecommendedDeckCacheStore {
  @override
  Future<List<Map<String, dynamic>>?> loadDecks() async => null;

  @override
  Future<void> saveDecks(List<Map<String, dynamic>> decks) async {}
}

class _FakeCardRepository implements CardRepository {
  @override
  Future<List<String>> fetchSeriesList() async => [];

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async => [];

  @override
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _topNav = Key('homeWideTopNav');
const _main = Key('homeWideMain');
const _sidebar = Key('homeWideSidebar');
const _primaryEntries = Key('homeWidePrimaryEntries');
const _quickActions = Key('homeWideQuickActions');

Future<void> pumpHome(WidgetTester tester, Size size, {required bool isWeb}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  final container = ProviderContainer(overrides: [
    isWebPlatformProvider.overrideWithValue(isWeb),
    authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
    metaRepositoryProvider.overrideWithValue(_FakeMetaRepository()),
    cardRepositoryProvider.overrideWithValue(_FakeCardRepository()),
    cardCacheStoreProvider.overrideWithValue(_EmptyCardCacheStore()),
    recommendedDeckRepositoryProvider.overrideWithValue(_FakeRecommendedDeckRepository()),
    recommendedDeckCacheStoreProvider.overrideWithValue(_EmptyRecommendedDeckCacheStore()),
  ]);
  addTearDown(container.dispose);

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('zh'),
      supportedLocales: kSupportedLocales,
      localizationsDelegates: kLocalizationsDelegates,
      home: const HomeScreen(),
    ),
  ));
  await tester.pump();
  await tester.pump();
}

List<String?> textsUnder(WidgetTester tester, Finder ancestor) {
  return tester
      .widgetList<Text>(find.descendant(of: ancestor, matching: find.byType(Text)))
      .map((text) => text.data)
      .toList();
}

void expectMobileLayout(WidgetTester tester) {
  expect(find.byType(BottomAppBar), findsOneWidget);
  expect(textsUnder(tester, find.byType(BottomAppBar)), ['首頁', '牌組', '消息', '個人']);

  expect(find.byType(GridView), findsOneWidget);
  expect(textsUnder(tester, find.byType(GridView)), ['對戰環境', '智能組牌', '我的牌組', '上位卡組', '戰績紀錄', '約戰地點']);
  final grid = tester.widget<GridView>(find.byType(GridView));
  final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  expect(delegate.crossAxisCount, 3);
  expect(delegate.childAspectRatio, 0.95);

  // 由上而下的順序：頁首、搜尋列、橫幅、快捷入口、對戰環境預覽（標題列、內容）。
  final finders = [
    find.text('UA DECK'),
    find.byType(TextField),
    find.text('熱門活動橫幅'),
    find.byType(GridView),
    find.text('查看更多 >'),
    find.text('測試系列'),
  ];
  final tops = finders.map((finder) => tester.getTopLeft(finder).dy).toList();
  for (var i = 1; i < tops.length; i++) {
    expect(tops[i], greaterThan(tops[i - 1]), reason: '${finders[i - 1]} 應該在 ${finders[i]} 上方');
  }
}

void expectNoWideSections() {
  expect(find.byKey(_topNav), findsNothing);
  expect(find.byKey(_main), findsNothing);
  expect(find.byKey(_sidebar), findsNothing);
}

Finder textIn(Key section, String text) {
  return find.descendant(of: find.byKey(section), matching: find.text(text));
}

void expectWideLayout(WidgetTester tester) {
  expect(find.byType(BottomAppBar), findsNothing);
  expect(find.byType(GridView), findsNothing);

  for (final label in ['首頁', '牌組', '消息', '個人']) {
    expect(textIn(_topNav, label), findsOneWidget);
  }
  expect(textIn(_main, '熱門活動橫幅'), findsOneWidget);
  for (final label in ['智能組牌', '我的牌組', '推薦牌組']) {
    expect(textIn(_primaryEntries, label), findsOneWidget);
  }
  for (final label in ['對戰環境', '戰績紀錄', '約戰地點']) {
    expect(textIn(_quickActions, label), findsOneWidget);
  }
  expect(find.text('上位卡組'), findsNothing);
  expect(textIn(_sidebar, '查看更多 >'), findsOneWidget);
  expect(textIn(_sidebar, '測試系列'), findsOneWidget);

  expect(tester.getTopLeft(find.byKey(_sidebar)).dx, greaterThanOrEqualTo(tester.getTopRight(find.byKey(_main)).dx));
  expect(tester.getBottomLeft(find.byKey(_topNav)).dy, lessThanOrEqualTo(tester.getTopLeft(find.byKey(_main)).dy));
}

void main() {
  testWidgets('非網頁 390x844 是手機版面', (tester) async {
    await pumpHome(tester, const Size(390, 844), isWeb: false);
    expectMobileLayout(tester);
    expectNoWideSections();
  });

  testWidgets('非網頁 1400x900 即使視窗很寬也是手機版面', (tester) async {
    await pumpHome(tester, const Size(1400, 900), isWeb: false);
    expectMobileLayout(tester);
    expectNoWideSections();
  });

  testWidgets('網頁 999x800 還是手機版面', (tester) async {
    await pumpHome(tester, const Size(999, 800), isWeb: true);
    expectMobileLayout(tester);
    expectNoWideSections();
  });

  testWidgets('網頁 1000x800 是寬螢幕版面，最窄寬度也排得下', (tester) async {
    await pumpHome(tester, const Size(1000, 800), isWeb: true);
    expectWideLayout(tester);
  });

  testWidgets('網頁 1400x900 是寬螢幕版面', (tester) async {
    await pumpHome(tester, const Size(1400, 900), isWeb: true);
    expectWideLayout(tester);
  });

  testWidgets('寬螢幕頂部導覽的「個人」和底部導覽列一樣開訪客對話框', (tester) async {
    await pumpHome(tester, const Size(1400, 900), isWeb: true);

    await tester.tap(textIn(_topNav, '個人'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('個人設定'), findsOneWidget);
  });

  testWidgets('寬螢幕主要入口「智能組牌」會開組牌頁', (tester) async {
    await pumpHome(tester, const Size(1400, 900), isWeb: true);

    await tester.tap(textIn(_primaryEntries, '智能組牌'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(DeckBuilderScreen), findsOneWidget);
  });
}
