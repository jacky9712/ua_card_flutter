import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/card_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/card_library_view_model.dart';

class _FakeCardRepository implements CardRepository {
  final List<String> searchCalls = [];
  int fetchCalls = 0;
  bool failSearch = false;

  Completer<List<String>>? seriesCompleter;
  bool failSeries = false;

  List<UACard> browseResult = const [];
  Completer<List<UACard>>? browseCompleter;
  bool failFetch = false;

  List<UACard> searchResult = const [];

  @override
  Future<List<String>> fetchSeriesList() async {
    if (failSeries) throw Exception('series down');
    if (seriesCompleter != null) return seriesCompleter!.future;
    return [];
  }

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    fetchCalls++;
    if (failFetch) throw Exception('network down');
    if (browseCompleter != null) return browseCompleter!.future;
    return browseResult;
  }

  @override
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    searchCalls.add(query);
    if (failSearch) throw Exception('network down');
    return searchResult;
  }

  @override
  Future<List<UACard>> fetchCardsByNumbers(List<String> cardNumbers) async => [];
}

void main() {
  late _FakeCardRepository repo;

  setUp(() {
    repo = _FakeCardRepository();
  });

  ProviderContainer makeContainer(FakeAsync async) {
    final container = ProviderContainer(overrides: [cardRepositoryProvider.overrideWithValue(repo)]);
    container.listen(cardLibraryViewModelProvider, (_, _) {});
    async.flushMicrotasks(); // 讓 _initData() 跑完
    return container;
  }

  test('連續快速輸入三次，只會用最後一個搜尋字查一次', () {
    fakeAsync((async) {
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);

      vm.updateSearchQuery('a');
      async.elapse(const Duration(milliseconds: 100));
      vm.updateSearchQuery('ab');
      async.elapse(const Duration(milliseconds: 100));
      vm.updateSearchQuery('abc');

      expect(container.read(cardLibraryViewModelProvider).searchQuery, 'abc');
      expect(repo.searchCalls, isEmpty);

      async.elapse(CardLibraryViewModel.searchDebounce);
      expect(repo.searchCalls, ['abc']);

      container.dispose();
    });
  });

  test('debounce 時間內清空搜尋字，不會送出搜尋', () {
    fakeAsync((async) {
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);

      vm.updateSearchQuery('ab');
      vm.updateSearchQuery('');
      async.elapse(const Duration(seconds: 1));

      expect(repo.searchCalls, isEmpty);
      container.dispose();
    });
  });

  test('搜尋後清空搜尋字，立刻回到系列瀏覽，不等 debounce', () {
    fakeAsync((async) {
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);

      vm.updateSearchQuery('ab');
      async.elapse(CardLibraryViewModel.searchDebounce);
      expect(repo.searchCalls, ['ab']);
      final fetchCallsBefore = repo.fetchCalls;

      vm.updateSearchQuery('');
      async.flushMicrotasks();

      expect(repo.fetchCalls, fetchCallsBefore + 1);
      container.dispose();
    });
  });

  test('搜尋失敗時回報 searchCardsFailed，並關掉 loading', () {
    fakeAsync((async) {
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);
      repo.failSearch = true;

      vm.updateSearchQuery('x');
      async.elapse(CardLibraryViewModel.searchDebounce);
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.error?.code, AppErrorCode.searchCardsFailed);
      expect(state.isLoading, isFalse);
      container.dispose();
    });
  });

  test('dispose 時取消還沒觸發的 debounce timer', () {
    fakeAsync((async) {
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);

      vm.updateSearchQuery('x');
      container.dispose();
      async.elapse(const Duration(seconds: 1));

      expect(repo.searchCalls, isEmpty);
      expect(async.pendingTimers, isEmpty);
    });
  });

  test('系列清單一直沒回來，第一頁卡片照樣載入', () {
    fakeAsync((async) {
      repo.seriesCompleter = Completer<List<String>>(); // 永遠不完成
      repo.browseResult = [UACard(id: 1, cardNumber: 'UA01BT-001')];
      final container = makeContainer(async);

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.allCards, hasLength(1));
      expect(state.isLoading, isFalse);
      expect(repo.fetchCalls, 1);
      container.dispose();
    });
  });

  test('系列清單失敗不影響卡片', () {
    fakeAsync((async) {
      repo.failSeries = true;
      repo.browseResult = [UACard(id: 1, cardNumber: 'UA01BT-001')];
      final container = makeContainer(async);

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.allCards, hasLength(1));
      expect(state.isLoading, isFalse);
      expect(state.availableSeries, isEmpty);
      expect(repo.fetchCalls, 1);
      container.dispose();
    });
  });

  test('卡片失敗後系列才回來，錯誤不會被清掉', () {
    fakeAsync((async) {
      final seriesCompleter = Completer<List<String>>();
      repo.seriesCompleter = seriesCompleter;
      repo.failFetch = true;
      final container = makeContainer(async);

      seriesCompleter.complete(['UA01']);
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.error?.code, AppErrorCode.dbConnectionFailed);
      expect(state.availableSeries, ['UA01']);
      container.dispose();
    });
  });

  test('預載還在跑時送出搜尋，結果是搜尋的不是瀏覽的', () {
    fakeAsync((async) {
      final browseCompleter = Completer<List<UACard>>();
      repo.browseCompleter = browseCompleter;
      repo.searchResult = [UACard(id: 2, cardNumber: 'UA02BT-001', name: 'abc')];
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);

      vm.updateSearchQuery('abc'); // 跟首頁搜尋框送出時同一個呼叫
      async.elapse(CardLibraryViewModel.searchDebounce);
      async.flushMicrotasks();

      // 預載的瀏覽結果比搜尋晚回來
      browseCompleter.complete([UACard(id: 1, cardNumber: 'UA01BT-001')]);
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.allCards.map((c) => c.cardNumber), ['UA02BT-001']);
      expect(state.filteredCards.map((c) => c.cardNumber), ['UA02BT-001']);
      expect(state.isLoading, isFalse);
      container.dispose();
    });
  });

  test('retryIfInitialLoadFailed 只在失敗且沒卡片時重抓', () {
    fakeAsync((async) {
      repo.failFetch = true;
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);
      expect(repo.fetchCalls, 1);
      expect(container.read(cardLibraryViewModelProvider).error, isNotNull);

      repo.failFetch = false;
      repo.browseResult = [UACard(id: 1, cardNumber: 'UA01BT-001')];
      vm.retryIfInitialLoadFailed();
      async.flushMicrotasks();
      expect(repo.fetchCalls, 2);
      expect(container.read(cardLibraryViewModelProvider).allCards, hasLength(1));

      vm.retryIfInitialLoadFailed(); // 已經有卡片、沒有錯誤，不再重抓
      async.flushMicrotasks();
      expect(repo.fetchCalls, 2);
      container.dispose();
    });
  });
}
