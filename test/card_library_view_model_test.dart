import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/card_cache_store.dart';
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
  int seriesCalls = 0;
  List<String> seriesResult = const [];

  List<UACard> browseResult = const [];
  Completer<List<UACard>>? browseCompleter;
  bool failFetch = false;

  List<UACard> searchResult = const [];

  final List<int> fetchOffsets = [];
  List<UACard> Function(int offset)? browseByOffset;

  @override
  Future<List<String>> fetchSeriesList() async {
    seriesCalls++;
    if (failSeries) throw Exception('series down');
    if (seriesCompleter != null) return seriesCompleter!.future;
    return seriesResult;
  }

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    fetchCalls++;
    fetchOffsets.add(offset);
    if (failFetch) throw Exception('network down');
    if (browseCompleter != null) return browseCompleter!.future;
    if (browseByOffset != null) return browseByOffset!(offset);
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

class _FakeCardCacheStore implements CardCacheStore {
  List<UACard>? cards;
  List<String>? series;
  Completer<void>? loadGate;
  bool throwOnLoad = false;
  final List<List<UACard>> savedCards = [];
  final List<List<String>> savedSeries = [];

  @override
  Future<List<UACard>?> loadFirstPage() async {
    if (loadGate != null) await loadGate!.future;
    if (throwOnLoad) throw Exception('boom');
    return cards;
  }

  @override
  Future<List<String>?> loadSeries() async => series;

  @override
  Future<void> saveFirstPage(List<UACard> cards) async => savedCards.add(cards);

  @override
  Future<void> saveSeries(List<String> series) async => savedSeries.add(series);
}

List<UACard> cardsN(int n, String prefix) =>
    List.generate(n, (i) => UACard(id: i, cardNumber: '$prefix-${i.toString().padLeft(3, '0')}'));

void main() {
  late _FakeCardRepository repo;
  late _FakeCardCacheStore cache;

  setUp(() {
    repo = _FakeCardRepository();
    cache = _FakeCardCacheStore();
  });

  ProviderContainer makeContainer(FakeAsync async, {List<AppError?>? errors}) {
    final container = ProviderContainer(overrides: [
      cardRepositoryProvider.overrideWithValue(repo),
      cardCacheStoreProvider.overrideWithValue(cache),
    ]);
    container.listen(cardLibraryViewModelProvider, (_, _) {});
    if (errors != null) {
      // 組牌頁的 SnackBar 只在 error 從 null 變成非 null 時跳，記下每一次 error 變化就能證明有沒有跳。
      container.listen(cardLibraryViewModelProvider.select((s) => s.error), (_, next) => errors.add(next));
    }
    async.flushMicrotasks(); // 讓 _initData() 跑完
    return container;
  }

  // 共用情境「離線開 App、畫面顯示快取」：快取有 2 張，快取先上畫面，初始請求接著失敗
  // （網路比讀快取早失敗的順序另外由「網路先失敗、快取後到」測）。之後的請求一律失敗。
  ProviderContainer startOfflineWithCache(FakeAsync async, List<AppError?> errors) {
    cache.cards = cardsN(2, 'C');
    final initial = Completer<List<UACard>>();
    repo.browseCompleter = initial;
    final container = makeContainer(async, errors: errors);
    repo.browseCompleter = null;
    repo.failFetch = true;
    initial.completeError(Exception('network down'));
    async.flushMicrotasks();
    final state = container.read(cardLibraryViewModelProvider);
    expect(state.allCards.map((c) => c.cardNumber), ['C-000', 'C-001']);
    expect(state.error, isNull);
    expect(state.isLoading, isFalse);
    expect(repo.fetchCalls, 1);
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

  test('系列清單失敗後 retrySeriesIfEmpty 重抓成功', () {
    fakeAsync((async) {
      repo.failSeries = true;
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);
      expect(container.read(cardLibraryViewModelProvider).availableSeries, isEmpty);
      expect(repo.seriesCalls, 1);

      repo.failSeries = false;
      repo.seriesResult = ['UA01', 'UA02'];
      vm.retrySeriesIfEmpty();
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(repo.seriesCalls, 2);
      expect(state.availableSeries, ['UA01', 'UA02']);
      expect(state.isLoadingSeries, isFalse);

      vm.retrySeriesIfEmpty(); // 已經有清單，不再重抓
      async.flushMicrotasks();
      expect(repo.seriesCalls, 2);
      container.dispose();
    });
  });

  test('系列請求進行中重複觸發只送一次', () {
    fakeAsync((async) {
      final seriesCompleter = Completer<List<String>>();
      repo.seriesCompleter = seriesCompleter;
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);
      expect(repo.seriesCalls, 1);
      expect(container.read(cardLibraryViewModelProvider).isLoadingSeries, isTrue);

      vm.retrySeriesIfEmpty();
      vm.retrySeriesIfEmpty();
      async.flushMicrotasks();
      expect(repo.seriesCalls, 1);

      seriesCompleter.complete(['UA01']);
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.availableSeries, ['UA01']);
      expect(state.isLoadingSeries, isFalse);
      container.dispose();
    });
  });

  test('重抓系列不清掉卡片錯誤、不動卡片狀態', () {
    fakeAsync((async) {
      repo.failFetch = true;
      repo.failSeries = true;
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);
      final failed = container.read(cardLibraryViewModelProvider);
      expect(failed.error?.code, AppErrorCode.dbConnectionFailed);
      expect(failed.isLoading, isFalse);
      expect(failed.allCards, isEmpty);

      repo.failSeries = false;
      repo.seriesResult = ['UA01'];
      vm.retrySeriesIfEmpty();
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.error?.code, AppErrorCode.dbConnectionFailed);
      expect(state.isLoading, isFalse);
      expect(state.allCards, isEmpty);
      expect(repo.fetchCalls, 1);
      expect(state.availableSeries, ['UA01']);
      container.dispose();
    });
  });

  test('重抓系列不影響進行中的卡片請求（_requestId 不變）', () {
    fakeAsync((async) {
      repo.failSeries = true;
      final browseCompleter = Completer<List<UACard>>();
      repo.browseCompleter = browseCompleter;
      final container = makeContainer(async);
      final vm = container.read(cardLibraryViewModelProvider.notifier);

      repo.failSeries = false;
      repo.seriesResult = ['UA01'];
      vm.retrySeriesIfEmpty();
      async.flushMicrotasks();
      expect(container.read(cardLibraryViewModelProvider).isLoading, isTrue);

      browseCompleter.complete([UACard(id: 1, cardNumber: 'UA01BT-001')]);
      async.flushMicrotasks();

      final state = container.read(cardLibraryViewModelProvider);
      expect(state.allCards, hasLength(1));
      expect(state.isLoading, isFalse);
      expect(repo.fetchCalls, 1);
      container.dispose();
    });
  });

  group('第一頁本機快取', () {
    test('有快取：先顯示快取，背景成功後換新並更新快取', () {
      fakeAsync((async) {
        cache.cards = cardsN(1, 'OLD');
        cache.series = ['OLD'];
        final browseCompleter = Completer<List<UACard>>();
        final seriesCompleter = Completer<List<String>>();
        repo.browseCompleter = browseCompleter;
        repo.seriesCompleter = seriesCompleter;
        final container = makeContainer(async);

        final cached = container.read(cardLibraryViewModelProvider);
        expect(cached.allCards.map((c) => c.cardNumber), ['OLD-000']);
        expect(cached.availableSeries, ['OLD']);
        expect(cached.isLoading && cached.allCards.isEmpty, isFalse); // 組牌頁不會顯示全螢幕 loading
        expect(repo.fetchCalls, 1);

        final fresh = cardsN(2, 'NEW');
        browseCompleter.complete(fresh);
        seriesCompleter.complete(['UA01', 'UA02']);
        async.flushMicrotasks();

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.allCards.map((c) => c.cardNumber), ['NEW-000', 'NEW-001']);
        expect(state.filteredCards.map((c) => c.cardNumber), ['NEW-000', 'NEW-001']);
        expect(state.availableSeries, ['UA01', 'UA02']);
        expect(state.isLoading, isFalse);
        expect(cache.savedCards.last.map((c) => c.cardNumber), ['NEW-000', 'NEW-001']);
        expect(cache.savedSeries.last, ['UA01', 'UA02']);
        container.dispose();
      });
    });

    test('有快取：背景失敗保留快取、沒有 error', () {
      fakeAsync((async) {
        final errors = <AppError?>[];
        final container = startOfflineWithCache(async, errors);

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.allCards.map((c) => c.cardNumber), ['C-000', 'C-001']);
        expect(state.error, isNull);
        expect(state.isLoading, isFalse);
        expect(errors.whereType<AppError>(), isEmpty);
        container.dispose();
      });
    });

    test('沒快取：失敗行為不變', () {
      fakeAsync((async) {
        repo.failFetch = true;
        final container = makeContainer(async);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.error?.code, AppErrorCode.dbConnectionFailed);
        expect(state.allCards, isEmpty);
        expect(cache.savedCards, isEmpty);

        repo.failFetch = false;
        vm.retryIfInitialLoadFailed();
        async.flushMicrotasks();
        expect(repo.fetchCalls, 2);
        container.dispose();
      });
    });

    test('網路先失敗、快取後到：顯示快取並清掉錯誤', () {
      fakeAsync((async) {
        final gate = Completer<void>();
        cache.loadGate = gate;
        cache.cards = cardsN(2, 'C');
        repo.failFetch = true;
        final container = makeContainer(async);
        expect(container.read(cardLibraryViewModelProvider).error?.code, AppErrorCode.dbConnectionFailed);

        gate.complete();
        async.flushMicrotasks();

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.allCards.map((c) => c.cardNumber), ['C-000', 'C-001']);
        expect(state.error, isNull);
        container.dispose();
      });
    });

    test('快取晚到不會蓋掉已經回來的搜尋結果', () {
      fakeAsync((async) {
        final gate = Completer<void>();
        cache.loadGate = gate;
        cache.cards = cardsN(2, 'C');
        final browseCompleter = Completer<List<UACard>>();
        repo.browseCompleter = browseCompleter;
        repo.searchResult = [UACard(id: 2, cardNumber: 'UA02BT-001', name: 'abc')];
        final container = makeContainer(async);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        vm.updateSearchQuery('abc');
        async.elapse(CardLibraryViewModel.searchDebounce);
        async.flushMicrotasks();

        gate.complete();
        async.flushMicrotasks();
        browseCompleter.complete([UACard(id: 1, cardNumber: 'UA01BT-001')]);
        async.flushMicrotasks();

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.allCards.map((c) => c.cardNumber), ['UA02BT-001']);
        expect(state.filteredCards.map((c) => c.cardNumber), ['UA02BT-001']);
        container.dispose();
      });
    });

    test('只快取預設瀏覽', () {
      fakeAsync((async) {
        repo.browseResult = cardsN(3, 'A');
        repo.searchResult = cardsN(1, 'S');
        final container = makeContainer(async);
        final vm = container.read(cardLibraryViewModelProvider.notifier);
        expect(cache.savedCards, hasLength(1));

        vm.updateSelectedSeries('UA01');
        async.flushMicrotasks();
        vm.updateSelectedColors({'RED'});
        async.flushMicrotasks();
        vm.updateSearchQuery('x');
        async.elapse(CardLibraryViewModel.searchDebounce);
        async.flushMicrotasks();

        expect(repo.fetchCalls, 3);
        expect(repo.searchCalls, ['x']);
        expect(cache.savedCards, hasLength(1));
        container.dispose();
      });
    });

    test('快取時 loadMore 不動作；換新後分頁正常', () {
      fakeAsync((async) {
        cache.cards = cardsN(3, 'C');
        final browseCompleter = Completer<List<UACard>>();
        repo.browseCompleter = browseCompleter;
        final container = makeContainer(async);
        final vm = container.read(cardLibraryViewModelProvider.notifier);
        expect(container.read(cardLibraryViewModelProvider).hasMore, isFalse);

        vm.loadMore();
        async.flushMicrotasks();
        expect(repo.fetchOffsets, [0]);

        browseCompleter.complete(cardsN(60, 'A'));
        async.flushMicrotasks();
        expect(container.read(cardLibraryViewModelProvider).hasMore, isTrue);

        repo.browseCompleter = null;
        repo.browseByOffset = (o) => cardsN(5, 'B');
        vm.loadMore();
        async.flushMicrotasks();

        final state = container.read(cardLibraryViewModelProvider);
        expect(repo.fetchOffsets, [0, 60]);
        expect(state.allCards, hasLength(65));
        expect(state.hasMore, isFalse);
        container.dispose();
      });
    });

    test('快取讀取丟例外視為沒快取', () {
      fakeAsync((async) {
        cache.throwOnLoad = true;
        repo.browseResult = cardsN(1, 'A');
        final container = makeContainer(async);

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.allCards.map((c) => c.cardNumber), ['A-000']);
        expect(state.error, isNull);
        container.dispose();
      });
    });

    test('快取讀取丟例外且網路失敗：照常 dbConnectionFailed', () {
      fakeAsync((async) {
        cache.throwOnLoad = true;
        repo.failFetch = true;
        final container = makeContainer(async);

        final state = container.read(cardLibraryViewModelProvider);
        expect(state.error?.code, AppErrorCode.dbConnectionFailed);
        expect(state.allCards, isEmpty);
        container.dispose();
      });
    });

    test('顯示快取時打開組牌頁會在背景刷新一次：成功換新', () {
      fakeAsync((async) {
        final errors = <AppError?>[];
        final container = startOfflineWithCache(async, errors);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        repo.failFetch = false;
        repo.browseResult = cardsN(3, 'F');
        vm.retryIfInitialLoadFailed();
        async.flushMicrotasks();

        final state = container.read(cardLibraryViewModelProvider);
        expect(repo.fetchCalls, 2);
        expect(state.allCards.map((c) => c.cardNumber), ['F-000', 'F-001', 'F-002']);
        expect(state.filteredCards.map((c) => c.cardNumber), ['F-000', 'F-001', 'F-002']);
        expect(cache.savedCards.last.map((c) => c.cardNumber), ['F-000', 'F-001', 'F-002']);
        expect(errors.whereType<AppError>(), isEmpty);

        vm.retryIfInitialLoadFailed(); // 已經換成新資料、沒有錯誤，不再重抓
        async.flushMicrotasks();
        expect(repo.fetchCalls, 2);
        container.dispose();
      });
    });

    test('顯示快取時打開組牌頁會在背景刷新一次：失敗保留快取，下次再試', () {
      fakeAsync((async) {
        final errors = <AppError?>[];
        final container = startOfflineWithCache(async, errors);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        vm.retryIfInitialLoadFailed();
        async.flushMicrotasks();

        final state = container.read(cardLibraryViewModelProvider);
        expect(repo.fetchCalls, 2);
        expect(state.allCards.map((c) => c.cardNumber), ['C-000', 'C-001']);
        expect(state.error, isNull);
        expect(state.isLoading, isFalse);
        expect(errors.whereType<AppError>(), isEmpty);

        vm.retryIfInitialLoadFailed();
        async.flushMicrotasks();
        expect(repo.fetchCalls, 3);
        container.dispose();
      });
    });

    test('顯示快取時打開組牌頁會在背景刷新一次：請求還在飛就不重複送', () {
      fakeAsync((async) {
        cache.cards = cardsN(2, 'C');
        final browseCompleter = Completer<List<UACard>>();
        repo.browseCompleter = browseCompleter;
        final container = makeContainer(async);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        final cached = container.read(cardLibraryViewModelProvider);
        expect(cached.allCards.map((c) => c.cardNumber), ['C-000', 'C-001']);
        expect(cached.isLoading, isTrue);
        expect(repo.fetchCalls, 1);

        vm.retryIfInitialLoadFailed();
        vm.retryIfInitialLoadFailed();
        async.flushMicrotasks();
        expect(repo.fetchCalls, 1);

        browseCompleter.complete(cardsN(3, 'F'));
        async.flushMicrotasks();
        expect(container.read(cardLibraryViewModelProvider).allCards.map((c) => c.cardNumber), ['F-000', 'F-001', 'F-002']);
        expect(repo.fetchCalls, 1);
        container.dispose();
      });
    });

    test('顯示快取時換系列失敗，error 照常設定', () {
      fakeAsync((async) {
        final errors = <AppError?>[];
        final container = startOfflineWithCache(async, errors);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        vm.updateSelectedSeries('UA01');
        async.flushMicrotasks();

        expect(container.read(cardLibraryViewModelProvider).error?.code, AppErrorCode.dbConnectionFailed);
        expect(errors.whereType<AppError>(), isNotEmpty);
        container.dispose();
      });
    });

    test('顯示快取時換顏色失敗，error 照常設定', () {
      fakeAsync((async) {
        final errors = <AppError?>[];
        final container = startOfflineWithCache(async, errors);
        final vm = container.read(cardLibraryViewModelProvider.notifier);

        vm.updateSelectedColors({'RED'});
        async.flushMicrotasks();

        expect(container.read(cardLibraryViewModelProvider).error?.code, AppErrorCode.dbConnectionFailed);
        expect(errors.whereType<AppError>(), isNotEmpty);
        container.dispose();
      });
    });

    test('顯示快取時搜尋失敗，error 照常設定且不會變成刷新快取', () {
      fakeAsync((async) {
        final errors = <AppError?>[];
        final container = startOfflineWithCache(async, errors);
        final vm = container.read(cardLibraryViewModelProvider.notifier);
        repo.failSearch = true;

        vm.updateSearchQuery('abc');
        async.elapse(CardLibraryViewModel.searchDebounce);
        async.flushMicrotasks();

        expect(container.read(cardLibraryViewModelProvider).error?.code, AppErrorCode.searchCardsFailed);
        expect(errors.whereType<AppError>(), isNotEmpty);

        vm.retryIfInitialLoadFailed();
        async.flushMicrotasks();
        expect(repo.fetchCalls, 1);
        expect(repo.searchCalls, hasLength(1));
        container.dispose();
      });
    });
  });
}
