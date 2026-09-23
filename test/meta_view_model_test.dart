import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/repositories/meta_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/viewModels/meta_view_model.dart';

class _FakeMetaRepository implements MetaRepository {
  _FakeMetaRepository({this.fail = false});

  bool fail;

  @override
  Future<List<Map<String, dynamic>>> fetchEnvironmentData() async {
    if (fail) throw Exception('network down');
    return [
      {'name_zh': '測試系列', 'share_rate': 42.0},
    ];
  }
}

void main() {
  ProviderContainer makeContainer(_FakeMetaRepository repo) {
    final container = ProviderContainer(overrides: [metaRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    return container;
  }

  test('抓取失敗時記錄 loadFailed，而不是當成沒資料', () async {
    final container = makeContainer(_FakeMetaRepository(fail: true));
    await container.read(metaViewModelProvider.notifier).fetchMetaEnvironment();

    final state = container.read(metaViewModelProvider);
    expect(state.loadFailed, isTrue);
    expect(state.isLoading, isFalse);
    expect(state.metaData, isEmpty);
    expect(state.fetchedAt, isNull);
  });

  test('重試成功後清掉 loadFailed 並記錄抓取時間', () async {
    final repo = _FakeMetaRepository(fail: true);
    final container = makeContainer(repo);
    final notifier = container.read(metaViewModelProvider.notifier);
    await notifier.fetchMetaEnvironment();

    repo.fail = false;
    await notifier.fetchMetaEnvironment();

    final state = container.read(metaViewModelProvider);
    expect(state.loadFailed, isFalse);
    expect(state.metaData, hasLength(1));
    expect(state.fetchedAt, isNotNull);
  });
}
