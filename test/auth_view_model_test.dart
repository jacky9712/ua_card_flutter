import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/my_deck_cache_store.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/viewModels/auth_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  User? user;
  bool failSignOut = false;

  @override
  User? get currentUser => user;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  Future<void> signOut() async {
    if (failSignOut) throw Exception('network down');
    user = null;
  }

  @override
  Future<void> signInAnonymously() async {
    user = _user('anon', isAnonymous: true);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMyDeckCacheStore implements MyDeckCacheStore {
  final cleared = <String>[];

  @override
  Future<void> clearUser(String userId) async => cleared.add(userId);

  @override
  Future<List<Map<String, dynamic>>?> loadDecks(String userId) async => null;

  @override
  Future<void> saveDecks(String userId, List<Map<String, dynamic>> decks) async {}

  @override
  Future<List<UACard>?> loadDeckCards(String userId, int deckId) async => null;

  @override
  Future<void> saveDeckCards(String userId, int deckId, List<UACard> cards) async {}
}

User _user(String id, {bool isAnonymous = false}) => User(
      id: id,
      appMetadata: const {},
      userMetadata: const {},
      aud: 'authenticated',
      createdAt: '',
      isAnonymous: isAnonymous,
    );

void main() {
  late _FakeAuthRepository auth;
  late _FakeMyDeckCacheStore cache;

  setUp(() {
    auth = _FakeAuthRepository();
    cache = _FakeMyDeckCacheStore();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(auth),
      myDeckCacheStoreProvider.overrideWithValue(cache),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('已登入帳號登出：清掉這個帳號的牌組快取，並換成新的匿名身分', () async {
    auth.user = _user('me');
    final container = makeContainer();

    await container.read(authViewModelProvider.notifier).signOut();

    expect(cache.cleared, ['me']);
    expect(auth.user?.isAnonymous, isTrue);
    expect(container.read(authViewModelProvider).error, isNull);
  });

  test('匿名身分登出：沒有雲端牌組快取，不清', () async {
    auth.user = _user('anon-old', isAnonymous: true);
    final container = makeContainer();

    await container.read(authViewModelProvider.notifier).signOut();

    expect(cache.cleared, isEmpty);
  });

  test('登出失敗：人還是登入狀態，快取留著，並回報 signOutFailed', () async {
    auth.user = _user('me');
    auth.failSignOut = true;
    final container = makeContainer();

    await container.read(authViewModelProvider.notifier).signOut();

    expect(cache.cleared, isEmpty);
    expect(container.read(authViewModelProvider).error?.code, AppErrorCode.signOutFailed);
  });
}
