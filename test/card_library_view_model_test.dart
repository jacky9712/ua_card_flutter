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

  @override
  Future<List<String>> fetchSeriesList() async => [];

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    fetchCalls++;
    return [];
  }

  @override
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    searchCalls.add(query);
    if (failSearch) throw Exception('network down');
    return [];
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
}
