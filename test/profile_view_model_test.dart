import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/profile_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/profile_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  User? user;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeProfileRepository implements ProfileRepository {
  bool failFetch = false;
  bool failUpdate = false;
  final fetchedIds = <String>[];
  final updatedNames = <String>[];
  Map<String, dynamic>? profile = {'display_name': '阿明'};

  @override
  Future<Map<String, dynamic>?> fetchProfile(String userId) async {
    fetchedIds.add(userId);
    if (failFetch) throw Exception('network down');
    return profile;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchProfiles(List<String> userIds) async => [];

  @override
  Future<void> updateDisplayName(String displayName) async {
    if (failUpdate) throw Exception('update denied');
    updatedNames.add(displayName);
  }
}

User _user(String id) =>
    User(id: id, appMetadata: const {}, userMetadata: const {}, aud: 'authenticated', createdAt: '');

void main() {
  late _FakeAuthRepository auth;
  late _FakeProfileRepository profiles;

  setUp(() {
    auth = _FakeAuthRepository();
    profiles = _FakeProfileRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      profileRepositoryProvider.overrideWithValue(profiles),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('沒登入時不查資料庫', () async {
    final container = makeContainer();
    await container.read(profileViewModelProvider.notifier).fetchMyProfile();

    expect(profiles.fetchedIds, isEmpty);
    expect(container.read(profileViewModelProvider).displayName, isNull);
  });

  test('登入後載入自己的暱稱', () async {
    auth.user = _user('me');
    final container = makeContainer();
    await container.read(profileViewModelProvider.notifier).fetchMyProfile();

    final state = container.read(profileViewModelProvider);
    expect(profiles.fetchedIds, contains('me'));
    expect(state.displayName, '阿明');
    expect(state.isLoading, isFalse);
  });

  test('載入失敗記錄 loadProfileFailed', () async {
    auth.user = _user('me');
    profiles.failFetch = true;
    final container = makeContainer();
    await container.read(profileViewModelProvider.notifier).fetchMyProfile();

    final state = container.read(profileViewModelProvider);
    expect(state.error?.code, AppErrorCode.loadProfileFailed);
    expect(state.isLoading, isFalse);
  });

  test('改暱稱成功：回傳 true 並更新畫面上的暱稱', () async {
    final container = makeContainer();

    final ok = await container.read(profileViewModelProvider.notifier).updateDisplayName('小美');

    expect(ok, isTrue);
    expect(profiles.updatedNames, ['小美']);
    expect(container.read(profileViewModelProvider).displayName, '小美');
  });

  test('改暱稱失敗：回傳 false 並記錄 updateNicknameFailed', () async {
    profiles.failUpdate = true;
    final container = makeContainer();

    final ok = await container.read(profileViewModelProvider.notifier).updateDisplayName('小美');

    expect(ok, isFalse);
    final state = container.read(profileViewModelProvider);
    expect(state.error?.code, AppErrorCode.updateNicknameFailed);
    expect(state.isLoading, isFalse);
  });

  test('初始載入比改暱稱晚跑完，也不會蓋掉 updateNicknameFailed', () async {
    auth.user = _user('me');
    profiles.failUpdate = true;
    final container = makeContainer();

    final ok = await container.read(profileViewModelProvider.notifier).updateDisplayName('小美');
    await pumpEventQueue(); // build() 排的初始載入在這之後才跑完

    expect(ok, isFalse);
    expect(container.read(profileViewModelProvider).error?.code, AppErrorCode.updateNicknameFailed);
  });
}
