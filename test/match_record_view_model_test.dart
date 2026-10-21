import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/repositories/match_record_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/match_record_view_model.dart';

class _FakeMatchRecordRepository implements MatchRecordRepository {
  _FakeMatchRecordRepository({this.failDelete = false});

  final bool failDelete;
  final records = <Map<String, dynamic>>[
    {'id': 1, 'result': 'win'},
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchMyMatchRecords() async => List.of(records);

  @override
  Future<void> deleteMatchRecord(int id) async {
    if (failDelete) throw Exception('permission denied');
    records.removeWhere((r) => r['id'] == id);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  ProviderContainer makeContainer(_FakeMatchRecordRepository repo) {
    final container = ProviderContainer(overrides: [matchRecordRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    return container;
  }

  test('刪除成功回傳 true 並重新載入列表', () async {
    final container = makeContainer(_FakeMatchRecordRepository());
    final success = await container.read(matchRecordViewModelProvider.notifier).deleteMatchRecord(1);

    expect(success, isTrue);
    expect(container.read(matchRecordViewModelProvider).records, isEmpty);
  });

  test('刪除失敗回傳 false 並記錄 deleteFailed，畫面才能提示', () async {
    final container = makeContainer(_FakeMatchRecordRepository(failDelete: true));
    final success = await container.read(matchRecordViewModelProvider.notifier).deleteMatchRecord(1);

    expect(success, isFalse);
    expect(container.read(matchRecordViewModelProvider).error?.code, AppErrorCode.deleteFailed);
  });
}
