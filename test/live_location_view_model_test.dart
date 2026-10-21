import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ua_card_flutter/repositories/live_location_repository.dart';
import 'package:ua_card_flutter/repositories/providers.dart';
import 'package:ua_card_flutter/viewModels/live_location_view_model.dart';

class _FakeLiveLocationRepository implements LiveLocationRepository {
  _FakeLiveLocationRepository({this.mySharingUntil});

  DateTime? mySharingUntil;

  @override
  Future<DateTime?> fetchMySharingUntil() async => mySharingUntil;

  @override
  Future<List<Map<String, dynamic>>> fetchActiveLiveLocations() async => [];

  @override
  Future<void> upsertMyLocation({required double lat, required double lng, required DateTime expiresAt}) async {}

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
}
