import 'dart:async';

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
  int seriesCalls = 0;
  bool failSeries = false;
  List<String> seriesResult = const [];
  Completer<List<String>>? seriesCompleter;

  @override
  Future<List<String>> fetchSeriesList() async {
    seriesCalls++;
    if (failSeries) throw Exception('series down');
    if (seriesCompleter != null) return seriesCompleter!.future;
    return seriesResult;
  }

  @override
  Future<List<UACard>> fetchCards({String? series, List<String>? colors, int limit = 60, int offset = 0}) async => [];

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

  testWidgets('系列預載失敗，打開組牌頁會在背景重抓一次', (tester) async {
    repo.failSeries = true;
    final container = makeContainer();
    container.listen(cardLibraryViewModelProvider, (_, _) {});

    await tester.pumpWidget(wrap(container, const SizedBox()));
    await tester.pump();
    expect(repo.seriesCalls, 1);

    repo.failSeries = false;
    repo.seriesResult = ['UA01BT'];
    await tester.pumpWidget(wrap(container, const DeckBuilderScreen()));
    await tester.pump();
    await tester.pump();
    expect(repo.seriesCalls, 2);
    expect(container.read(cardLibraryViewModelProvider).availableSeries, ['UA01BT']);

    // 已經有清單，不會一直重試
    await tester.pump(const Duration(seconds: 1));
    expect(repo.seriesCalls, 2);
  });

  testWidgets('系列清單空的時候打開選單會重抓，載入中顯示 loading，資料到了選單跟著更新', (tester) async {
    repo.failSeries = true;
    final container = makeContainer();
    container.listen(cardLibraryViewModelProvider, (_, _) {});

    await tester.pumpWidget(wrap(container, const DeckBuilderScreen()));
    await tester.pump();
    await tester.pump();
    expect(container.read(cardLibraryViewModelProvider).availableSeries, isEmpty);
    final before = repo.seriesCalls;

    repo.failSeries = false;
    final seriesCompleter = Completer<List<String>>();
    repo.seriesCompleter = seriesCompleter;

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500)); // spinner 不會停，不能用 pumpAndSettle
    expect(repo.seriesCalls, before + 1);
    expect(find.byKey(const Key('seriesPickerLoading')), findsOneWidget);
    expect(find.text('UA01BT'), findsNothing);

    seriesCompleter.complete(['UA01BT']);
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const Key('seriesPickerLoading')), findsNothing);
    expect(find.text('UA01BT'), findsOneWidget);
  });
}
