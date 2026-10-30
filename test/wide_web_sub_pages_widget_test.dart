import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/main.dart';
import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/card_cache_store.dart';
import 'package:ua_card_flutter/repositories/card_repository.dart';
import 'package:ua_card_flutter/repositories/deck_repository.dart';
import 'package:ua_card_flutter/repositories/deck_share_code_repository.dart';
import 'package:ua_card_flutter/repositories/meta_repository.dart';
import 'package:ua_card_flutter/repositories/my_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_repository.dart';
import 'package:ua_card_flutter/screens/deck_builder_screen.dart';
import 'package:ua_card_flutter/screens/recommended_decks_screen.dart';
import 'package:ua_card_flutter/screens/deck_detail_screen.dart';
import 'package:ua_card_flutter/screens/login_screen.dart';
import 'package:ua_card_flutter/screens/meta_environment_screen.dart';
import 'package:ua_card_flutter/screens/my_decks_screen.dart';
import 'package:ua_card_flutter/utils/wide_web_layout.dart';
import 'package:ua_card_flutter/widgets/wide_web_content.dart';

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

// fetchCompleter 不完成，畫面停在骨架，不會建出 CachedNetworkImage。
class _FakeCardRepository implements CardRepository {
  final Completer<List<UACard>> fetchCompleter = Completer();

  @override
  Future<List<String>> fetchSeriesList() async => [];

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) =>
      fetchCompleter.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 測試牌組不帶 cover_image_url，不會建出 CachedNetworkImage。
class _FakeRecommendedDeckRepository implements RecommendedDeckRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks() async => [
        {'id': 1, 'name': '牌組一'},
        {'id': 2, 'name': '牌組二'},
        {'id': 3, 'name': '牌組三'},
      ];

  @override
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId) async => [];
}

class _EmptyRecommendedDeckCacheStore implements RecommendedDeckCacheStore {
  @override
  Future<List<Map<String, dynamic>>?> loadDecks() async => null;

  @override
  Future<void> saveDecks(List<Map<String, dynamic>> decks) async {}
}

// 測試牌組不帶 cover_card_url，不會建出 CachedNetworkImage。
class _FakeDeckRepository implements DeckRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchLocalDecks() async => [
        {'id': -1, 'name': '本機牌組', 'series_id': 2, 'cards': []},
      ];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMyDeckCacheStore implements MyDeckCacheStore {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeckShareCodeRepository implements DeckShareCodeRepository {
  @override
  Future<DeckShareCode> createShareCode(String deckString) async =>
      DeckShareCode(code: '012345', expiresAt: DateTime(2026, 10, 23, 15, 30));

  @override
  Future<DeckShareCode?> findMyShareCode(String deckString) async => null;
}

void main() {
  const deckNames = ['牌組一', '牌組二', '牌組三'];

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Size size,
    required bool isWeb,
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        isWebPlatformProvider.overrideWithValue(isWeb),
        authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ...overrides,
      ],
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: screen,
      ),
    ));
  }

  Future<void> pumpBuilder(WidgetTester tester, {required Size size, required bool isWeb}) async {
    await pumpScreen(tester, const DeckBuilderScreen(), size: size, isWeb: isWeb, overrides: [
      metaRepositoryProvider.overrideWithValue(_FakeMetaRepository()),
      cardRepositoryProvider.overrideWithValue(_FakeCardRepository()),
      cardCacheStoreProvider.overrideWithValue(_EmptyCardCacheStore()),
    ]);
    await tester.pump();
    await tester.pump();
  }

  Future<void> pumpRecommended(WidgetTester tester, {required Size size, required bool isWeb}) async {
    await pumpScreen(tester, const RecommendedDecksScreen(), size: size, isWeb: isWeb, overrides: [
      recommendedDeckRepositoryProvider.overrideWithValue(_FakeRecommendedDeckRepository()),
      recommendedDeckCacheStoreProvider.overrideWithValue(_EmptyRecommendedDeckCacheStore()),
    ]);
    await tester.pumpAndSettle();
  }

  GridView skeletonGrid(WidgetTester tester) => tester.widget<GridView>(
        find.descendant(of: find.byKey(const Key('cardSkeletonShimmer')), matching: find.byType(GridView)),
      );

  void expectSkeleton(WidgetTester tester, {required int columns, required int items, double? extent}) {
    final grid = skeletonGrid(tester);
    final delegate = grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, columns);
    expect(delegate.childAspectRatio, 0.54);
    expect(delegate.mainAxisExtent, extent);
    expect(grid.childrenDelegate.estimatedChildCount, items);
  }

  void expectBuilderMobile(WidgetTester tester) => expectSkeleton(tester, columns: 3, items: 9);

  Finder deckCard(String name) => find.widgetWithText(Card, name);

  void expectRecommendedMobile(WidgetTester tester, double windowWidth) {
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(GridView), findsNothing);
    final positions = deckNames.map((name) => tester.getTopLeft(deckCard(name))).toList();
    expect(positions[1].dx, positions[0].dx);
    expect(positions[2].dx, positions[0].dx);
    expect(positions[1].dy, greaterThan(positions[0].dy));
    expect(positions[2].dy, greaterThan(positions[1].dy));
    expect(tester.getSize(find.byType(ListView)).width, windowWidth);
  }

  group('WideWebContent 幾何', () {
    const content = Key('content');

    Future<void> pumpContent(
      WidgetTester tester, {
      required Size size,
      required bool isWeb,
      double maxWidth = wideWebContentMaxWidth,
    }) =>
        pumpScreen(
          tester,
          Scaffold(body: WideWebContent(maxWidth: maxWidth, child: const SizedBox.expand(key: content))),
          size: size,
          isWeb: isWeb,
        );

    testWidgets('網頁 1400 寬：內容寬 960 且置中', (tester) async {
      await pumpContent(tester, size: const Size(1400, 900), isWeb: true);
      expect(tester.getSize(find.byKey(content)).width, 960);
      expect(tester.getCenter(find.byKey(content)).dx, 700);
    });

    testWidgets('網頁 1000 寬：內容寬 960 且置中', (tester) async {
      await pumpContent(tester, size: const Size(1000, 800), isWeb: true);
      expect(tester.getSize(find.byKey(content)).width, 960);
      expect(tester.getCenter(find.byKey(content)).dx, 500);
    });

    testWidgets('表單上限：內容寬 560', (tester) async {
      await pumpContent(tester, size: const Size(1400, 900), isWeb: true, maxWidth: wideWebFormMaxWidth);
      expect(tester.getSize(find.byKey(content)).width, 560);
    });

    testWidgets('上限比視窗寬時不會出現負的留白', (tester) async {
      await pumpContent(tester, size: const Size(1000, 800), isWeb: true, maxWidth: wideWebListMaxWidth);
      expect(tester.getSize(find.byKey(content)).width, 1000);
    });

    const narrowCases = <(String, Size, bool)>[
      ('網頁 999×800', Size(999, 800), true),
      ('非網頁 1400×900', Size(1400, 900), false),
    ];
    for (final (label, size, isWeb) in narrowCases) {
      testWidgets('非寬版不多包 Padding：$label', (tester) async {
        await pumpContent(tester, size: size, isWeb: isWeb);
        expect(tester.getSize(find.byKey(content)).width, size.width);
        expect(find.descendant(of: find.byType(WideWebContent), matching: find.byType(Padding)), findsNothing);
      });
    }
  });

  group('欄數計算', () {
    test('wideWebCardCellExtent 是卡圖高度加按鈕列與邊框', () {
      expect(wideWebCardCellExtent(1000, 5), closeTo(311.84, 0.01));
      expect(wideWebCardCellExtent(1920, 8), closeTo(369.1, 0.01));
    });

    test('wideWebCardGridCount 隨寬度增加，上限 8', () {
      expect(wideWebCardGridCount(1000), 5);
      expect(wideWebCardGridCount(1400), 7);
      expect(wideWebCardGridCount(1600), 8);
      expect(wideWebCardGridCount(1920), 8);
      expect(wideWebCardGridCount(3840), 8);
    });

    test('wideWebDeckColumnCount 在 1280 從 2 欄變 3 欄', () {
      expect(wideWebDeckColumnCount(1000), 2);
      expect(wideWebDeckColumnCount(1279), 2);
      expect(wideWebDeckColumnCount(1280), 3);
    });
  });

  group('智能組牌寬版骨架', () {
    const cases = <(Size, int, int)>[
      (Size(1000, 800), 5, 15),
      (Size(1400, 900), 7, 21),
      (Size(1920, 1080), 8, 24),
    ];
    for (final (size, columns, items) in cases) {
      testWidgets('網頁 ${size.width}：$columns 欄、$items 項', (tester) async {
        await pumpBuilder(tester, size: size, isWeb: true);
        expectSkeleton(tester, columns: columns, items: items, extent: wideWebCardCellExtent(size.width, columns));
      });
    }
  });

  group('推薦牌組寬版', () {
    const grid = Key('recommendedDecksWideGrid');

    int columnsOf(WidgetTester tester) =>
        (tester.widget<GridView>(find.byKey(grid)).gridDelegate as SliverGridDelegateWithFixedCrossAxisCount)
            .crossAxisCount;

    testWidgets('網頁 1000 寬：2 欄，沒有清單', (tester) async {
      await pumpRecommended(tester, size: const Size(1000, 800), isWeb: true);
      expect(columnsOf(tester), 2);
      expect(find.byType(ListView), findsNothing);
    });

    testWidgets('網頁 1400 寬：3 欄同列，卡片可點', (tester) async {
      await pumpRecommended(tester, size: const Size(1400, 900), isWeb: true);
      expect(columnsOf(tester), 3);
      expect(find.byType(ListView), findsNothing);

      final positions = deckNames.map((name) => tester.getTopLeft(deckCard(name))).toList();
      expect(positions[1].dy, positions[0].dy);
      expect(positions[2].dy, positions[0].dy);
      expect(positions[1].dx, greaterThan(positions[0].dx));
      expect(positions[2].dx, greaterThan(positions[1].dx));

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile));
      expect(tiles, hasLength(3));
      expect(tiles.every((tile) => tile.onTap != null), isTrue);
    });
  });

  group('子頁有接上 WideWebContent（網頁 1400×900）', () {
    const webWide = Size(1400, 900);

    void expectSidePadding(WidgetTester tester, double side) {
      final padding = tester.widget<Padding>(
        find.descendant(of: find.byType(WideWebContent), matching: find.byType(Padding)).first,
      );
      expect(padding.padding, EdgeInsets.symmetric(horizontal: side));
    }

    final detailOverrides = <Override>[
      deckShareCodeRepositoryProvider.overrideWithValue(_FakeDeckShareCodeRepository()),
    ];
    // 不帶 imageUrl，且直接開在 QR 分頁，不會建出 CachedNetworkImage。
    final detailCards = [UACard(id: 1, cardNumber: 'UA01BT-001')];

    testWidgets('MyDecksScreen', (tester) async {
      await pumpScreen(tester, const MyDecksScreen(), size: webWide, isWeb: true, overrides: [
        deckRepositoryProvider.overrideWithValue(_FakeDeckRepository()),
        myDeckCacheStoreProvider.overrideWithValue(_FakeMyDeckCacheStore()),
      ]);
      await tester.pumpAndSettle();
      expectSidePadding(tester, 220);
    });

    testWidgets('MetaEnvironmentScreen', (tester) async {
      await pumpScreen(tester, const MetaEnvironmentScreen(), size: webWide, isWeb: true, overrides: [
        metaRepositoryProvider.overrideWithValue(_FakeMetaRepository()),
      ]);
      await tester.pumpAndSettle();
      expectSidePadding(tester, 220);
    });

    testWidgets('DeckDetailScreen', (tester) async {
      await pumpScreen(
        tester,
        DeckDetailScreen(deckName: 'T', cardsInDeck: detailCards, initialTabIndex: 1),
        size: webWide,
        isWeb: true,
        overrides: detailOverrides,
      );
      await tester.pump();
      expectSidePadding(tester, 220);
      expect(find.byType(WideWebContent), findsOneWidget);
    });

    testWidgets('DeckDetailScreen 有儲存按鈕時，按鈕也限寬', (tester) async {
      await pumpScreen(
        tester,
        DeckDetailScreen(deckName: 'T', cardsInDeck: detailCards, initialTabIndex: 1, onSavePressed: () {}),
        size: webWide,
        isWeb: true,
        overrides: detailOverrides,
      );
      await tester.pump();
      expect(find.byType(WideWebContent), findsNWidgets(2));
    });

    testWidgets('LoginScreen 用表單寬度', (tester) async {
      await pumpScreen(tester, const LoginScreen(), size: webWide, isWeb: true);
      await tester.pump();
      expectSidePadding(tester, 420);
    });
  });

  group('非寬版畫面不變', () {
    const cases = <(String, Size, bool)>[
      ('非網頁 390×844', Size(390, 844), false),
      ('非網頁 1400×900', Size(1400, 900), false),
      ('網頁 999×800', Size(999, 800), true),
    ];

    for (final (label, size, isWeb) in cases) {
      testWidgets('智能組牌維持 3 欄：$label', (tester) async {
        await pumpBuilder(tester, size: size, isWeb: isWeb);
        expectBuilderMobile(tester);
      });

      testWidgets('推薦牌組維持單欄清單：$label', (tester) async {
        await pumpRecommended(tester, size: size, isWeb: isWeb);
        expectRecommendedMobile(tester, size.width);
      });
    }
  });
}
