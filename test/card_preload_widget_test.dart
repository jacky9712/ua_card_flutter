import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:ua_card_flutter/main.dart';
import 'package:ua_card_flutter/models/ua_card.dart';
import 'package:ua_card_flutter/repositories/auth_repository.dart';
import 'package:ua_card_flutter/repositories/card_cache_store.dart';
import 'package:ua_card_flutter/repositories/card_repository.dart';
import 'package:ua_card_flutter/repositories/meta_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/screens/deck_builder_screen.dart';
import 'package:ua_card_flutter/screens/home_screen.dart';
import 'package:ua_card_flutter/viewModels/card_library_view_model.dart';

class _FakeAuthRepository implements AuthRepository {
  @override
  User? get currentUser => null;

  @override
  Stream<AuthState> get onAuthStateChange => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeMetaRepository implements MetaRepository {
  @override
  Future<List<Map<String, dynamic>>> fetchEnvironmentData() async => [];
}

// 空的快取：widget 測試不碰 SharedPreferences 平台通道。
class _EmptyCardCacheStore implements CardCacheStore {
  @override
  Future<List<UACard>?> loadFirstPage() async => null;

  @override
  Future<List<String>?> loadSeries() async => null;

  @override
  Future<void> saveFirstPage(List<UACard> cards) async {}

  @override
  Future<void> saveSeries(List<String> series) async {}
}

class _FakeCardRepository implements CardRepository {
  int fetchCalls = 0;
  bool failFetch = false;

  @override
  Future<List<String>> fetchSeriesList() async => [];

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async {
    fetchCalls++;
    if (failFetch) throw Exception('network down');
    return [];
  }

  @override
  Future<List<UACard>> searchCards(String query, {String? series, List<String>? colors, int limit = 60, int offset = 0}) async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _FakeCardRepository repo;

  setUp(() {
    repo = _FakeCardRepository();
  });

  ProviderContainer makeContainer() {
    final container = ProviderContainer(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
      metaRepositoryProvider.overrideWithValue(_FakeMetaRepository()),
      cardRepositoryProvider.overrideWithValue(repo),
      cardCacheStoreProvider.overrideWithValue(_EmptyCardCacheStore()),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  Widget wrap(ProviderContainer container, Widget home) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        locale: const Locale('zh'),
        supportedLocales: kSupportedLocales,
        localizationsDelegates: kLocalizationsDelegates,
        home: home,
      ),
    );
  }

  testWidgets('首頁一顯示就開始預載卡片，不用進組牌頁', (tester) async {
    final container = makeContainer();

    await tester.pumpWidget(wrap(container, const HomeScreen()));
    await tester.pump();
    await tester.pump();

    expect(repo.fetchCalls, 1);
    expect(find.byType(DeckBuilderScreen), findsNothing);
    expect(container.exists(cardLibraryViewModelProvider), isTrue);
  });

  testWidgets('預載失敗後打開組牌頁會自動重抓一次', (tester) async {
    repo.failFetch = true;
    final container = makeContainer();
    container.listen(cardLibraryViewModelProvider, (_, _) {});

    await tester.pumpWidget(wrap(container, const SizedBox()));
    await tester.pump();

    expect(repo.fetchCalls, 1);
    final failed = container.read(cardLibraryViewModelProvider);
    expect(failed.error, isNotNull);
    expect(failed.allCards, isEmpty);

    await tester.pumpWidget(wrap(container, const DeckBuilderScreen()));
    await tester.pump();
    await tester.pump();
    expect(repo.fetchCalls, 2);

    // 重抓還是失敗，但不會一直重試
    await tester.pump(const Duration(seconds: 1));
    expect(repo.fetchCalls, 2);
  });
}
