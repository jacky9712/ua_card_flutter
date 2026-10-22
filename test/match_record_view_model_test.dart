import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/match_record_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/match_record_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  User? user;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  ProviderContainer makeContainer(_FakeMatchRecordRepository repo, {_FakeAuthRepository? auth}) {
    final container = ProviderContainer(overrides: [
      matchRecordRepositoryProvider.overrideWithValue(repo),
      authRepositoryProvider.overrideWithValue(auth ?? _FakeAuthRepository()),
    ]);
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

  test('登出後重新載入，myUserId 會清成 null，不留上一個帳號的 id', () async {
    final auth = _FakeAuthRepository()
      ..user = User(id: 'me', appMetadata: const {}, userMetadata: const {}, aud: 'authenticated', createdAt: '');
    final container = makeContainer(_FakeMatchRecordRepository(), auth: auth);
    final vm = container.read(matchRecordViewModelProvider.notifier);

    await vm.fetchMyMatchRecords();
    expect(container.read(matchRecordViewModelProvider).myUserId, 'me');

    auth.user = null;
    await vm.fetchMyMatchRecords();
    expect(container.read(matchRecordViewModelProvider).myUserId, isNull);
  });

  group('MatchRecordState 總統計從我的角度算', () {
    test('別人記他贏了我，在我的統計算成敗場', () {
      final state = MatchRecordState(myUserId: 'me', records: [
        {'player_id': 'other', 'opponent_id': 'me', 'result': 'win'},
      ]);

      expect(state.winCount, 0);
      expect(state.lossCount, 1);
      expect(state.winRate, 0);
    });

    test('混合我記的與別人記的紀錄，平手不入分母', () {
      final state = MatchRecordState(myUserId: 'me', records: [
        {'player_id': 'me', 'opponent_id': 'other', 'result': 'win'},
        {'player_id': 'me', 'opponent_id': 'other', 'result': 'draw'},
        {'player_id': 'other', 'opponent_id': 'me', 'result': 'loss'},
        {'player_id': 'other', 'opponent_id': 'me', 'result': 'win'},
      ]);

      expect(state.totalCount, 4);
      expect(state.winCount, 2);
      expect(state.lossCount, 1);
      expect(state.drawCount, 1);
      expect(state.winRate, closeTo(66.67, 0.01));
    });
  });
}
