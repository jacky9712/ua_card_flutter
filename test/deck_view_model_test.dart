import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/card_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/deck_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

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

void main() {
  ProviderContainer makeContainer(List<UACard> cards) {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      cardRepositoryProvider.overrideWithValue(_FakeCardRepository(cards)),
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
}
