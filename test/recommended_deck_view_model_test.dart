import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/repositories/recommended_deck_repository.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/recommended_deck_view_model.dart';

class _FakeRecommendedDeckRepository implements RecommendedDeckRepository {
  bool fail = false;
  final requestedDeckIds = <int>[];

  @override
  Future<List<Map<String, dynamic>>> fetchRecommendedDecks() async {
    if (fail) throw Exception('network down');
    return [
      {'id': 7, 'name': 'Tier 1 紅'},
    ];
  }

  @override
  Future<List<UACard>> fetchRecommendedDeckCards(int deckId) async {
    requestedDeckIds.add(deckId);
    return [UACard(id: 1, cardNumber: 'UA01BT/BLC-1-001')];
  }
}

void main() {
  late _FakeRecommendedDeckRepository repo;

  setUp(() => repo = _FakeRecommendedDeckRepository());

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [recommendedDeckRepositoryProvider.overrideWithValue(repo)]);
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
}
