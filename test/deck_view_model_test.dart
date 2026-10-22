import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/card_repository.dart';
import 'package:ua_card_flutter/repositories/deck_repository.dart';
import 'package:ua_card_flutter/repositories/my_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/deck_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  User? user;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCardRepository implements CardRepository {
  _FakeCardRepository(this.cards);

  final List<UACard> cards;

  @override
  Future<List<UACard>> fetchCardsByNumbers(List<String> cardNumbers) async =>
      cards.where((c) => cardNumbers.contains(c.cardNumber)).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDeckRepository implements DeckRepository {
  bool failRemote = false;
  bool failRemoteCards = false;
  List<Map<String, dynamic>> local = [
    {'id': -1, 'name': '本機牌組', 'series_id': 2, 'cards': []},
  ];
  List<Map<String, dynamic>> remote = [
    {'id': 10, 'name': '雲端牌組', 'series_id': 3, 'total_price': 500},
  ];
  List<UACard> remoteCards = [
    UACard(id: 1, cardNumber: 'UA01BT-001', price: 300, seriesId: 3),
    UACard(id: 1, cardNumber: 'UA01BT-001', price: 300, seriesId: 3),
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchLocalDecks() async => local;

  @override
  Future<List<Map<String, dynamic>>> fetchRemoteDecks(String userId) async {
    if (failRemote) throw Exception('network down');
    return remote;
  }

  @override
  Future<List<UACard>> fetchRemoteDeckCards(int deckId) async {
    if (failRemoteCards) throw Exception('network down');
    return remoteCards;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// 假的快取：測試不碰 SharedPreferences 平台通道。
class _FakeMyDeckCacheStore implements MyDeckCacheStore {
  final Map<String, List<Map<String, dynamic>>> decks = {};
  final Map<String, List<UACard>> cards = {};
  int loadCalls = 0;

  @override
  Future<List<Map<String, dynamic>>?> loadDecks(String userId) async {
    loadCalls++;
    return decks[userId];
  }

  @override
  Future<void> saveDecks(String userId, List<Map<String, dynamic>> decks) async {
    this.decks[userId] = decks;
  }

  @override
  Future<List<UACard>?> loadDeckCards(String userId, int deckId) async {
    loadCalls++;
    return cards['$userId/$deckId'];
  }

  @override
  Future<void> saveDeckCards(String userId, int deckId, List<UACard> cards) async {
    this.cards['$userId/$deckId'] = cards;
  }
}

User _user(String id) =>
    User(id: id, appMetadata: const {}, userMetadata: const {}, aud: 'authenticated', createdAt: '');

void main() {
  late _FakeAuthRepository auth;
  late _FakeDeckRepository decks;
  late _FakeMyDeckCacheStore cache;

  setUp(() {
    auth = _FakeAuthRepository();
    decks = _FakeDeckRepository();
    cache = _FakeMyDeckCacheStore();
  });

  ProviderContainer makeContainer(List<UACard> cards) {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      cardRepositoryProvider.overrideWithValue(_FakeCardRepository(cards)),
      deckRepositoryProvider.overrideWithValue(decks),
      myDeckCacheStoreProvider.overrideWithValue(cache),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('沒有任何卡號對得上時回傳 false，牌組不變', () async {
    final container = makeContainer([]);
    final success = await container.read(deckViewModelProvider.notifier).importDeckFromQR('UA_DECK|ZZ-999:4');

    expect(success, isFalse);
    final state = container.read(deckViewModelProvider);
    expect(state.error?.code, AppErrorCode.importDeckFailed);
    expect(state.deckMap, isEmpty);
    expect(state.isLoading, isFalse);
  });

  test('前綴不對回傳 false 並回報 importDeckFailed', () async {
    final container = makeContainer([]);
    final success = await container.read(deckViewModelProvider.notifier).importDeckFromQR('hello');

    expect(success, isFalse);
    expect(container.read(deckViewModelProvider).error?.code, AppErrorCode.importDeckFailed);
  });

  test('匯入成功時張數夾到 4，並可展開成卡片清單', () async {
    final container = makeContainer([UACard(id: 1, cardNumber: 'UA01BT-001')]);
    final success = await container.read(deckViewModelProvider.notifier).importDeckFromQR('UA_DECK|UA01BT-001:99');

    expect(success, isTrue);
    final state = container.read(deckViewModelProvider);
    expect(state.deckMap, {1: 4});
    expect(state.expandedCards.length, 4);
  });

  List<Object?> ids(ProviderContainer container) =>
      container.read(deckViewModelProvider).myDecks.map((d) => d['id']).toList();

  test('雲端失敗、沒快取：本機牌組照常顯示，不回報 loadDecksFailed，標成離線', () async {
    auth.user = _user('me');
    decks.failRemote = true;
    final container = makeContainer([]);

    await container.read(deckViewModelProvider.notifier).fetchMyDecks();

    final state = container.read(deckViewModelProvider);
    expect(ids(container), [-1]);
    expect(state.error, isNull);
    expect(state.isOffline, isTrue);
    expect(state.offlineWithoutCache, isTrue); // 沒同步過：提示改說雲端牌組暫時無法顯示
    expect(state.isLoading, isFalse);
  });

  test('雲端失敗、有快取：顯示本機＋快取的雲端牌組，系列資料不退化', () async {
    auth.user = _user('me');
    decks.failRemote = true;
    cache.decks['me'] = [
      {'id': 10, 'name': '快取雲端', 'series_id': 3},
    ];
    final container = makeContainer([]);

    await container.read(deckViewModelProvider.notifier).fetchMyDecks();

    final state = container.read(deckViewModelProvider);
    expect(ids(container), [-1, 10]);
    expect(state.error, isNull);
    expect(state.isOffline, isTrue);
    expect(state.offlineWithoutCache, isFalse); // 有快取：提示寫「顯示上次同步的牌組」
    expect(state.myDecks.map((d) => d['series_id'] as int?).whereType<int>().toSet(), {2, 3});
  });

  test('雲端成功：寫回以使用者 id 區分的快取，不標離線', () async {
    auth.user = _user('me');
    final container = makeContainer([]);

    await container.read(deckViewModelProvider.notifier).fetchMyDecks();

    expect(cache.decks['me']!.map((d) => d['id']).toList(), [10]);
    expect(container.read(deckViewModelProvider).isOffline, isFalse);
    expect(ids(container), [-1, 10]);
  });

  test('離線後重試成功，離線狀態清掉', () async {
    auth.user = _user('me');
    decks.failRemote = true;
    final container = makeContainer([]);
    final notifier = container.read(deckViewModelProvider.notifier);

    await notifier.fetchMyDecks();
    expect(container.read(deckViewModelProvider).isOffline, isTrue);

    decks.failRemote = false;
    await notifier.fetchMyDecks();
    expect(container.read(deckViewModelProvider).isOffline, isFalse);
    expect(ids(container), [-1, 10]);
  });

  test('打開過的雲端牌組，離線時從快取讀卡表；沒快取的回 []', () async {
    auth.user = _user('me');
    final container = makeContainer([]);
    final notifier = container.read(deckViewModelProvider.notifier);

    final online = await notifier.fetchCardsForDeck(10);
    expect(online.length, decks.remoteCards.length);
    expect(cache.cards['me/10']!.length, decks.remoteCards.length);

    decks.failRemoteCards = true;
    final offline = await notifier.fetchCardsForDeck(10);
    expect(offline.length, decks.remoteCards.length);
    expect(offline.first.price, 300);

    expect(await notifier.fetchCardsForDeck(11), isEmpty);
  });

  test('未登入時雲端失敗也不碰快取、不標離線', () async {
    auth.user = null;
    decks.failRemote = true;
    decks.failRemoteCards = true;
    final container = makeContainer([]);
    final notifier = container.read(deckViewModelProvider.notifier);

    await notifier.fetchMyDecks();
    expect(await notifier.fetchCardsForDeck(10), isEmpty);

    expect(cache.loadCalls, 0);
    expect(container.read(deckViewModelProvider).isOffline, isFalse);
    expect(ids(container), [-1]);
  });
}
