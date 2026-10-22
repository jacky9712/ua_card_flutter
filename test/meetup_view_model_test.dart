import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ua_card_flutter/repositories/meetup_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/utils/location_platform.dart';
import 'package:ua_card_flutter/viewModels/meetup_view_model.dart';

class _FakeMeetupRepository implements MeetupRepository {
  bool failFetch = false;
  bool failCreate = false;
  bool failDelete = false;
  int fetchCalls = 0;
  final posts = <Map<String, dynamic>>[
    {'id': 1, 'location_name': '台北'},
  ];

  @override
  Future<List<Map<String, dynamic>>> fetchOpenMeetupPosts() async {
    fetchCalls++;
    if (failFetch) throw Exception('network down');
    return List.of(posts);
  }

  @override
  Future<void> createMeetupPost({
    required String locationName,
    double? lat,
    double? lng,
    String? note,
    DateTime? scheduledAt,
    int? deckId,
    String? deckNameSnapshot,
    String? deckTier,
  }) async {
    if (failCreate) throw Exception('insert denied');
    posts.add({'id': posts.length + 1, 'location_name': locationName});
  }

  @override
  Future<void> deleteMeetupPost(int id) async {
    if (failDelete) throw Exception('permission denied');
    posts.removeWhere((p) => p['id'] == id);
  }
}

Position _position(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026),
      accuracy: 0,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late _FakeMeetupRepository repo;

  setUp(() => repo = _FakeMeetupRepository());

  ProviderContainer makeContainer({PositionGetter? position}) {
    final container = ProviderContainer(overrides: [
      meetupRepositoryProvider.overrideWithValue(repo),
      if (position != null) currentPositionProvider.overrideWithValue(position),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  test('載入成功後列出貼文', () async {
    final container = makeContainer();
    await container.read(meetupViewModelProvider.notifier).fetchOpenMeetupPosts();

    final state = container.read(meetupViewModelProvider);
    expect(state.posts.map((p) => p['id']), [1]);
    expect(state.isLoading, isFalse);
    expect(state.error, isNull);
  });

  test('載入失敗記錄 loadMeetupsFailed', () async {
    repo.failFetch = true;
    final container = makeContainer();
    await container.read(meetupViewModelProvider.notifier).fetchOpenMeetupPosts();

    final state = container.read(meetupViewModelProvider);
    expect(state.error?.code, AppErrorCode.loadMeetupsFailed);
    expect(state.isLoading, isFalse);
  });

  test('發文成功回傳 true 並重新載入清單', () async {
    final container = makeContainer();
    final notifier = container.read(meetupViewModelProvider.notifier);
    final callsBefore = repo.fetchCalls;

    final ok = await notifier.createMeetupPost(locationName: '台中');

    expect(ok, isTrue);
    expect(repo.fetchCalls, greaterThan(callsBefore));
    expect(container.read(meetupViewModelProvider).posts.map((p) => p['location_name']), contains('台中'));
  });

  test('發文失敗回傳 false 並記錄 publishFailed', () async {
    repo.failCreate = true;
    final container = makeContainer();

    final ok = await container.read(meetupViewModelProvider.notifier).createMeetupPost(locationName: '台中');

    expect(ok, isFalse);
    final state = container.read(meetupViewModelProvider);
    expect(state.error?.code, AppErrorCode.publishFailed);
    expect(state.isLoading, isFalse);
  });

  test('刪除成功回傳 true 並重新載入清單', () async {
    final container = makeContainer();

    final ok = await container.read(meetupViewModelProvider.notifier).deleteMeetupPost(1);

    expect(ok, isTrue);
    expect(container.read(meetupViewModelProvider).posts, isEmpty);
  });

  test('刪除失敗回傳 false 並記錄 deleteFailed', () async {
    repo.failDelete = true;
    final container = makeContainer();

    final ok = await container.read(meetupViewModelProvider.notifier).deleteMeetupPost(1);

    expect(ok, isFalse);
    expect(container.read(meetupViewModelProvider).error?.code, AppErrorCode.deleteFailed);
  });

  test('切到最近距離但拿不到定位：記錄 locationFallbackToTime，排序維持時間序', () async {
    // 測試環境沒有定位外掛，getCurrentPositionOrNull() 會回 null，等同使用者拒絕權限。
    final container = makeContainer();

    await container.read(meetupViewModelProvider.notifier).setSortMode(MeetupSortMode.nearest);

    final state = container.read(meetupViewModelProvider);
    expect(state.error?.code, AppErrorCode.locationFallbackToTime);
    expect(state.sortMode, MeetupSortMode.soonest);
  });

  test('切到最近距離且拿到定位：記住座標、改成距離排序，之後切換不再重新定位', () async {
    repo.posts
      ..clear()
      ..addAll([
        {'id': 1, 'lat': 25.0, 'lng': 121.5}, // 台北
        {'id': 2},
        {'id': 3, 'lat': 22.6, 'lng': 120.3}, // 高雄
      ]);
    var positionCalls = 0;
    final container = makeContainer(position: () async {
      positionCalls++;
      return _position(22.63, 120.30);
    });
    final notifier = container.read(meetupViewModelProvider.notifier);
    await notifier.fetchOpenMeetupPosts();

    await notifier.setSortMode(MeetupSortMode.nearest);

    final state = container.read(meetupViewModelProvider);
    expect(state.error, isNull);
    expect(state.sortMode, MeetupSortMode.nearest);
    expect(state.myPosition?.latitude, 22.63);
    expect(state.sortedPosts.map((p) => p['id']), [3, 1, 2]);

    await notifier.setSortMode(MeetupSortMode.soonest);
    await notifier.setSortMode(MeetupSortMode.nearest);
    expect(positionCalls, 1);
  });

  group('MeetupState.sortedPosts', () {
    final far = {'id': 1, 'lat': 25.0, 'lng': 121.5}; // 台北
    final noCoords = {'id': 2};
    final near = {'id': 3, 'lat': 22.6, 'lng': 120.3}; // 高雄

    test('最近距離：由近到遠，沒有經緯度的排最後', () {
      final state = MeetupState(
        posts: [far, noCoords, near],
        sortMode: MeetupSortMode.nearest,
        myPosition: _position(22.63, 120.30),
      );
      expect(state.sortedPosts.map((p) => p['id']), [3, 1, 2]);
    });

    test('時間序或還沒有自己座標時維持原順序', () {
      expect(
        MeetupState(posts: [far, noCoords, near], myPosition: _position(22.63, 120.30))
            .sortedPosts
            .map((p) => p['id']),
        [1, 2, 3],
      );
      expect(
        MeetupState(posts: [far, noCoords, near], sortMode: MeetupSortMode.nearest)
            .sortedPosts
            .map((p) => p['id']),
        [1, 2, 3],
      );
    });
  });

  test('初始載入比切換排序晚跑完，也不會蓋掉 locationFallbackToTime', () async {
    final container = makeContainer(position: () async => null);
    final notifier = container.read(meetupViewModelProvider.notifier);

    await notifier.setSortMode(MeetupSortMode.nearest); // 初始載入還沒跑完
    await pumpEventQueue();

    expect(container.read(meetupViewModelProvider).error?.code, AppErrorCode.locationFallbackToTime);
  });
}
