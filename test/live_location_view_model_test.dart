import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:ua_card_flutter/repositories/live_location_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/utils/app_error.dart';
import 'package:ua_card_flutter/utils/location_platform.dart';
import 'package:ua_card_flutter/viewModels/live_location_view_model.dart';

class _FakeLiveLocationRepository implements LiveLocationRepository {
  _FakeLiveLocationRepository({this.mySharingUntil});

  DateTime? mySharingUntil;

  @override
  Future<DateTime?> fetchMySharingUntil() async => mySharingUntil;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveLiveLocations() async => [];

  final upserts = <(double, double)>[];

  @override
  Future<void> upsertMyLocation({required double lat, required double lng, required DateTime expiresAt}) async {
    upserts.add((lat, lng));
  }

  @override
  Future<void> stopSharing() async => mySharingUntil = null;
}

void main() {
  Future<LiveLocationState> buildAndSettle(_FakeLiveLocationRepository repo) async {
    final container = ProviderContainer(overrides: [liveLocationRepositoryProvider.overrideWithValue(repo)]);
    addTearDown(container.dispose);
    container.read(liveLocationViewModelProvider);
    // build() 透過 microtask 恢復狀態，等它跑完。
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container.read(liveLocationViewModelProvider);
  }

  test('重開時伺服器上還在分享，恢復成分享中狀態', () async {
    final until = DateTime.now().add(const Duration(minutes: 30));
    final state = await buildAndSettle(_FakeLiveLocationRepository(mySharingUntil: until));

    expect(state.isSharing, isTrue);
    expect(state.sharingUntil, until);
  });

  test('分享已過期或沒在分享時維持未分享', () async {
    final expired = await buildAndSettle(
      _FakeLiveLocationRepository(mySharingUntil: DateTime.now().subtract(const Duration(minutes: 1))),
    );
    expect(expired.isSharing, isFalse);

    final none = await buildAndSettle(_FakeLiveLocationRepository());
    expect(none.isSharing, isFalse);
    expect(none.sharingUntil, isNull);
  });

  Future<ProviderContainer> makeSettledContainer(_FakeLiveLocationRepository repo, PositionGetter position) async {
    final container = ProviderContainer(overrides: [
      liveLocationRepositoryProvider.overrideWithValue(repo),
      currentPositionProvider.overrideWithValue(position),
    ]);
    addTearDown(container.dispose); // dispose 時 VM 會取消定時回報的 Timer
    // build() 用 microtask 恢復狀態並抓附近的人，先等它跑完，免得測試結束 dispose 時還在寫 state。
    container.read(liveLocationViewModelProvider);
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return container;
  }

  test('開始分享且拿到定位：上傳座標、進入分享中', () async {
    final repo = _FakeLiveLocationRepository();
    final container = await makeSettledContainer(
      repo,
      () async => Position(
        latitude: 25.03,
        longitude: 121.56,
        timestamp: DateTime(2026),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      ),
    );

    final ok = await container.read(liveLocationViewModelProvider.notifier).startSharing(const Duration(minutes: 30));

    expect(ok, isTrue);
    expect(repo.upserts, [(25.03, 121.56)]);
    final state = container.read(liveLocationViewModelProvider);
    expect(state.isSharing, isTrue);
    expect(state.error, isNull);
  });

  test('開始分享但拿不到定位：不上傳、回報 locationUnavailable', () async {
    final repo = _FakeLiveLocationRepository();
    final container = await makeSettledContainer(repo, () async => null);

    final ok = await container.read(liveLocationViewModelProvider.notifier).startSharing(const Duration(minutes: 30));

    expect(ok, isFalse);
    expect(repo.upserts, isEmpty);
    final state = container.read(liveLocationViewModelProvider);
    expect(state.isSharing, isFalse);
    expect(state.error?.code, AppErrorCode.locationUnavailable);
  });
}
