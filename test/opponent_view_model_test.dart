import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/repositories/opponent_repository.dart';
import 'package:ua_card_flutter/repositories/profile_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/opponent_view_model.dart';

class _FakeOpponentRepository implements OpponentRepository {
  bool failFetch = false;
  bool failAdd = false;
  final known = <Map<String, dynamic>>[];
  final added = <String>[];

  @override
  Future<List<Map<String, dynamic>>> fetchKnownOpponents() async {
    if (failFetch) throw Exception('network down');
    return List.of(known);
  }

  @override
  Future<void> addKnownOpponent(String opponentId, {String? nickname}) async {
    if (failAdd) throw Exception('insert denied');
    added.add(opponentId);
    known.add({'opponent_id': opponentId});
  }

  @override
  Future<void> removeKnownOpponent(String opponentId) async {}
}

class _FakeProfileRepository implements ProfileRepository {
  final profiles = <String, Map<String, dynamic>>{};

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async => profiles[userId];

  @override
  Future<List<Map<String, dynamic>>> fetchProfiles(List<String> userIds) async => [];

  @override
  Future<void> updateDisplayName(String displayName) async {}
}

void main() {
  late _FakeOpponentRepository opponents;
  late _FakeProfileRepository profiles;

  setUp(() {
    opponents = _FakeOpponentRepository();
    profiles = _FakeProfileRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      opponentRepositoryProvider.overrideWithValue(opponents),
      profileRepositoryProvider.overrideWithValue(profiles),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('載入已知對手成功', () async {
    opponents.known.add({'opponent_id': 'u1'});
    final container = makeContainer();
    await container.read(opponentViewModelProvider.notifier).fetchKnownOpponents();

    final state = container.read(opponentViewModelProvider);
    expect(state.knownOpponents, hasLength(1));
    expect(state.error, isNull);
  });

  test('載入失敗記錄 loadOpponentsFailed', () async {
    opponents.failFetch = true;
    final container = makeContainer();
    await container.read(opponentViewModelProvider.notifier).fetchKnownOpponents();

    final state = container.read(opponentViewModelProvider);
    expect(state.error?.code, AppErrorCode.loadOpponentsFailed);
    expect(state.isLoading, isFalse);
  });

  group('addOpponentFromQr', () {
    test('格式不對或 id 是空的：invalidQr，不查資料庫', () async {
      final container = makeContainer();
      final notifier = container.read(opponentViewModelProvider.notifier);
      // build() 排了一次初始載入，它開始時會清掉 error；先讓它跑完，免得蓋掉這裡要檢查的錯誤。
      await pumpEventQueue();

      expect(await notifier.addOpponentFromQr('UA_DECK|abc'), isNull);
      expect(container.read(opponentViewModelProvider).error?.code, AppErrorCode.invalidQr);

      expect(await notifier.addOpponentFromQr('UA_PLAYER|   '), isNull);
      expect(container.read(opponentViewModelProvider).error?.code, AppErrorCode.invalidQr);
      expect(opponents.added, isEmpty);
    });

    test('查不到這個玩家：playerNotFound', () async {
      final container = makeContainer();

      expect(await container.read(opponentViewModelProvider.notifier).addOpponentFromQr('UA_PLAYER|ghost'), isNull);

      final state = container.read(opponentViewModelProvider);
      expect(state.error?.code, AppErrorCode.playerNotFound);
      expect(state.isLoading, isFalse);
      expect(opponents.added, isEmpty);
    });

    test('成功：加入清單、重新載入並回傳暱稱', () async {
      profiles.profiles['u1'] = {'display_name': '阿明'};
      final container = makeContainer();

      final name = await container.read(opponentViewModelProvider.notifier).addOpponentFromQr('UA_PLAYER|u1');

      expect(name, '阿明');
      expect(opponents.added, ['u1']);
      expect(container.read(opponentViewModelProvider).knownOpponents.map((o) => o['opponent_id']), contains('u1'));
    });

    test('對方沒設暱稱：回傳空字串（由畫面顯示「未命名玩家」）', () async {
      profiles.profiles['u2'] = {'display_name': null};
      final container = makeContainer();

      expect(await container.read(opponentViewModelProvider.notifier).addOpponentFromQr('UA_PLAYER|u2'), '');
    });

    test('加入失敗：addOpponentFailed', () async {
      profiles.profiles['u1'] = {'display_name': '阿明'};
      opponents.failAdd = true;
      final container = makeContainer();

      expect(await container.read(opponentViewModelProvider.notifier).addOpponentFromQr('UA_PLAYER|u1'), isNull);

      final state = container.read(opponentViewModelProvider);
      expect(state.error?.code, AppErrorCode.addOpponentFailed);
      expect(state.isLoading, isFalse);
    });
  });
}
