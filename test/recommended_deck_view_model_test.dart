import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_repository.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/recommended_deck_view_model.dart';

class _FakeRecommendedDeckRepository implements RecommendedDeckRepository {
  bool fail = false;
  Completer<List<Map<String, dynamic>>>? fetchCompleter;
  List<Map<String, dynamic>> result = [
    {'id': 7, 'name': 'Tier 1 紅'},
  ];
  final requestedDeckIds = <int>[];

  @override
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks() async {
    if (fail) throw Exception('network down');
    if (fetchCompleter != null) return fetchCompleter!.future;
    return result;
  }

  @override
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId) async {
    requestedDeckIds.add(deckId);
    return [UACard(id: 1, cardNumber: 'UA01BT/BLC-1-001')];
  }
}

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
      recommendedDeckRepositoryProvider.overrideWithValue(repo),
      recommendedDeckCacheStoreProvider.overrideWithValue(cache),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('載入推薦牌組成功', () async {
    final container = makeContainer();
    await container.read(recommendedDeckViewModelProvider.notifier).fetchRecommendedDecks();

    final state = container.read(recommendedDeckViewModelProvider);
    expect(state.decks.map((d) => d['id']), [7]);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('載入失敗記錄 loadTopDecksFailed', () async {
    repo.fail = true;
    final container = makeContainer();
    await container.read(recommendedDeckViewModelProvider.notifier).fetchRecommendedDecks();

    final state = container.read(recommendedDeckViewModelProvider);
    expect(state.error?.code, AppErrorCode.loadTopDecksFailed);
    expect(state.isLoading, isFalse);
    expect(state.decks, isEmpty);
  });

  test('重試成功後清掉錯誤', () async {
    repo.fail = true;
    final container = makeContainer();
    final notifier = container.read(recommendedDeckViewModelProvider.notifier);
    await notifier.fetchRecommendedDecks();

    repo.fail = false;
    await notifier.fetchRecommendedDecks();

    final state = container.read(recommendedDeckViewModelProvider);
    expect(state.error, isNull);
    expect(state.decks, hasLength(1));
  });

  test('fetchCardsForDeck 轉呼叫 repository', () async {
    final container = makeContainer();

    final cards = await container.read(recommendedDeckViewModelProvider.notifier).fetchCardsForDeck(7);

    expect(repo.requestedDeckIds, [7]);
    expect(cards.single.cardNumber, 'UA01BT/BLC-1-001');
  });

  test('有快取先顯示快取，背景更新成功後換新並寫回快取', () async {
    cache.cached = [
      {'id': 1, 'name': '快取'},
    ];
    repo.fetchCompleter = Completer();
    final container = makeContainer();
    container.read(recommendedDeckViewModelProvider);
    await Future<void>.delayed(Duration.zero);

    var state = container.read(recommendedDeckViewModelProvider);
    expect(state.decks.map((d) => d['id']), [1]);
    expect(state.isLoading, isTrue);
    expect(state.error, isNull);

    repo.fetchCompleter!.complete([
      {'id': 7, 'name': '新'},
    ]);
    await Future<void>.delayed(Duration.zero);

    state = container.read(recommendedDeckViewModelProvider);
    expect(state.decks.map((d) => d['id']), [7]);
    expect(state.isLoading, isFalse);
    expect(cache.saved?.map((d) => d['id']), [7]);
  });

  test('有快取時背景更新失敗，保留快取且不設 error', () async {
    cache.cached = [
      {'id': 1, 'name': '快取'},
    ];
    repo.fail = true;
    final container = makeContainer();
    container.read(recommendedDeckViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    final state = container.read(recommendedDeckViewModelProvider);
    expect(state.decks.map((d) => d['id']), [1]);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
    expect(cache.saved, isNull);
  });

  test('網路結果先到，晚到的快取不覆蓋', () async {
    cache.loadCompleter = Completer();
    final container = makeContainer();
    container.read(recommendedDeckViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(recommendedDeckViewModelProvider).decks.map((d) => d['id']), [7]);

    cache.loadCompleter!.complete([
      {'id': 1},
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(recommendedDeckViewModelProvider).decks.map((d) => d['id']), [7]);
  });

  test('網路先失敗、快取後到：顯示快取並清掉 error', () async {
    repo.fail = true;
    cache.loadCompleter = Completer();
    final container = makeContainer();
    container.read(recommendedDeckViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(recommendedDeckViewModelProvider).error?.code, AppErrorCode.loadTopDecksFailed);

    cache.loadCompleter!.complete([
      {'id': 1, 'name': '快取'},
    ]);
    await Future<void>.delayed(Duration.zero);
    final state = container.read(recommendedDeckViewModelProvider);
    expect(state.decks.map((d) => d['id']), [1]);
    expect(state.error, isNull);
  });
}
