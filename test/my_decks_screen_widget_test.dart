import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/main.dart';
import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/deck_repository.dart';
import 'package:ua_card_flutter/repositories/my_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/screens/my_decks_screen.dart';
import 'package:ua_card_flutter/viewModels/deck_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  User? user =
      User(id: 'me', appMetadata: const {}, userMetadata: const {}, aud: 'authenticated', createdAt: '');

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 測試牌組不帶 cover_card_url，不會建出 CachedNetworkImage。
class _FakeDeckRepository implements DeckRepository {
  bool failRemote = false;
  List<Map<String, dynamic>> local = [
    {'id': -1, 'name': '本機牌組', 'series_id': 2, 'cards': []},
  ];
  List<Map<String, dynamic>> remote = [
    {'id': 10, 'name': '雲端牌組', 'series_id': 3, 'total_price': 500},
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchLocalDecks() async => local;

  @override
  Future<List<Map<String, dynamic>>> fetchRemoteDecks(String userId) async {
    if (failRemote) throw Exception('network down');
    return remote;
  }

  @override
  Future<List<UACard>> fetchRemoteDeckCards(int deckId) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 假的快取：widget 測試不碰 SharedPreferences 平台通道。
class _FakeMyDeckCacheStore implements MyDeckCacheStore {
  final Map<String, List<Map<String, dynamic>>> decks = {};

  @override
  Future<List<Map<String, dynamic>>?> loadDecks(String userId) async => decks[userId];

  @override
  Future<void> saveDecks(String userId, List<Map<String, dynamic>> decks) async {
    this.decks[userId] = decks;
  }

  @override
  Future<List<UACard>?> loadDeckCards(String userId, int deckId) async => null;

  @override
  Future<void> saveDeckCards(String userId, int deckId, List<UACard> cards) async {}
}

void main() {
  late _FakeDeckRepository repo;
  late _FakeMyDeckCacheStore cache;

  setUp(() {
    repo = _FakeDeckRepository();
    cache = _FakeMyDeckCacheStore();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      deckRepositoryProvider.overrideWithValue(repo),
      myDeckCacheStoreProvider.overrideWithValue(cache),
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
        home: const MyDecksScreen(),
      ),
    );
  }

  const banner = Key('myDecksOfflineBanner');

  testWidgets('雲端失敗有快取：顯示快取牌組與離線提示；下拉重試成功後提示消失', (tester) async {
    repo.failRemote = true;
    cache.decks['me'] = [
      {'id': 10, 'name': '快取雲端', 'series_id': 3},
    ];
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    expect(find.text('本機牌組'), findsOneWidget);
    expect(find.text('快取雲端'), findsOneWidget);
    expect(find.byKey(banner), findsOneWidget);
    expect(find.text('無法連線，顯示上次同步的牌組'), findsOneWidget);
    expect(container.read(deckViewModelProvider).isOffline, isTrue);

    repo.failRemote = false;
    repo.remote = [
      {'id': 11, 'name': '新雲端', 'series_id': 3},
    ];
    final refresh = tester.widget<RefreshIndicator>(find.byType(RefreshIndicator)).onRefresh();
    await tester.pump();
    await refresh;
    await tester.pump();

    expect(find.byKey(banner), findsNothing);
    expect(find.text('新雲端'), findsOneWidget);
    expect(find.text('快取雲端'), findsNothing);
  });

  testWidgets('雲端成功不顯示離線提示', (tester) async {
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(banner), findsNothing);
    expect(find.text('雲端牌組'), findsOneWidget);
    expect(find.text('本機牌組'), findsOneWidget);
  });

  testWidgets('雲端失敗、沒快取、也沒本機牌組：顯示提示與 noDecksYet，仍有 RefreshIndicator', (tester) async {
    repo.failRemote = true;
    repo.local = [];
    final container = makeContainer();

    await tester.pumpWidget(wrap(container));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(banner), findsOneWidget);
    // 從沒同步過：不說「顯示上次同步的牌組」，改說雲端牌組暫時無法顯示
    expect(find.text('無法連線，雲端牌組暫時無法顯示'), findsOneWidget);
    expect(find.text('無法連線，顯示上次同步的牌組'), findsNothing);
    expect(find.text('目前還沒有任何牌組，快去組一套吧！'), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
  });
}
