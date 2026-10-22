import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/main.dart';
import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_repository.dart';
import 'package:ua_card_flutter/screens/recommended_decks_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 測試牌組不帶 cover_image_url，不會建出 CachedNetworkImage。
class _FakeRecommendedDeckRepository implements RecommendedDeckRepository {
  bool fail = false;
  bool failCards = false;
  int fetchCalls = 0;
  Completer<List<Map<String, dynamic>>>? fetchCompleter;
  List<Map<String, dynamic>> result = [
    {'id': 7, 'name': 'Tier 1 紅'},
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks() async {
    fetchCalls++;
    if (fail) throw Exception('network down');
    if (fetchCompleter != null) return fetchCompleter!.future;
    return result;
  }

  @override
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId) async {
    if (failCards) throw Exception('network down');
    return [];
  }
}

// 假的快取：widget 測試不碰 SharedPreferences 平台通道。
class _FakeRecommendedDeckCacheStore implements RecommendedDeckCacheStore {
  List<Map<String, dynamic>>? cached;
  Completer<List<Map<String, dynamic>>?>? loadCompleter;
  List<Map<String, dynamic>>? saved;

  @override
  Future<List<Map<String, dynamic>>?> loadDecks() async {
    if (loadCompleter != null) return loadCompleter!.future;
    return cached;
  }

  @override
  Future<void> saveDecks(List<Map<String, dynamic>> decks) async {
    saved = decks;
  }
}

void main() {
  late _FakeRecommendedDeckRepository repo;
  late _FakeRecommendedDeckCacheStore cache;

  setUp(() {
    repo = _FakeRecommendedDeckRepository();
    cache = _FakeRecommendedDeckCacheStore();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      recommendedDeckRepositoryProvider.overrideWithValue(repo),
      recommendedDeckCacheStoreProvider.overrideWithValue(cache),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Widget wrap(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: const RecommendedDecksScreen(),
      ),
    );
  }

  testWidgets('沒快取且載入失敗顯示錯誤與重試，重試成功後顯示清單', (tester) async {
    repo.fail = true;
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('recommendedDecksError')), findsOneWidget);
    expect(find.textContaining('載入上位卡組失敗'), findsOneWidget);
    expect(find.byKey(const Key('recommendedDecksRetryButton')), findsOneWidget);
    expect(find.text('目前尚無推薦牌組'), findsNothing);

    repo.fail = false;
    await tester.tap(find.byKey(const Key('recommendedDecksRetryButton')));
    await tester.pump();
    await tester.pump();

    expect(find.text('Tier 1 紅'), findsOneWidget);
    expect(find.byKey(const Key('recommendedDecksError')), findsNothing);
    expect(find.byKey(const Key('recommendedDecksRetryButton')), findsNothing);
  });

  testWidgets('有快取時背景更新失敗，繼續顯示快取、不顯示錯誤', (tester) async {
    cache.cached = [
      {'id': 1, 'name': '快取牌組'},
    ];
    repo.fail = true;
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    expect(find.text('快取牌組'), findsOneWidget);
    expect(find.byKey(const Key('recommendedDecksError')), findsNothing);
    expect(find.byKey(const Key('recommendedDecksRetryButton')), findsNothing);
    expect(find.byKey(const Key('recommendedDecksLoadingBar')), findsNothing);
  });

  testWidgets('有快取時背景更新中頂端顯示進度條，成功後換新', (tester) async {
    cache.cached = [
      {'id': 1, 'name': '快取牌組'},
    ];
    repo.fetchCompleter = Completer();
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    expect(find.text('快取牌組'), findsOneWidget);
    expect(find.byKey(const Key('recommendedDecksLoadingBar')), findsOneWidget);

    repo.fetchCompleter!.complete([
      {'id': 7, 'name': '新牌組'},
    ]);
    await tester.pump();
    await tester.pump();

    expect(find.text('新牌組'), findsOneWidget);
    expect(find.text('快取牌組'), findsNothing);
    expect(find.byKey(const Key('recommendedDecksLoadingBar')), findsNothing);
    expect(cache.saved?.map((d) => d['id']), [7]);
  });

  testWidgets('點牌組抓卡片失敗，轉圈會停並跳出提示', (tester) async {
    repo.failCards = true;
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Tier 1 紅'));
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('載入牌組卡表失敗，請稍後再試'), findsOneWidget);
    expect(tester.widget<ListTile>(find.byType(ListTile)).onTap, isNotNull);
  });
}
